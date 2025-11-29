unit KM_HouseArmorWorkshop;
{$I KaM_Remake.inc}
interface
uses
  KM_Houses,
  KM_ResTypes,
  KM_Defaults, KM_CommonClasses;

type
  TKMHouseArmorWorkshop = class(TKMHouse)
  private
    fAcceptWood: Boolean;
    fAcceptLeather: Boolean;
  public
    property AcceptWood: Boolean read fAcceptWood write fAcceptWood;
    property AcceptLeather: Boolean read fAcceptLeather write fAcceptLeather;
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;
    procedure ToggleResDelivery(aWareType: TKMWareType);
    function AcceptWareForDelivery(aWareType: TKMWareType): Boolean;
    function ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean; override;
  end;

implementation

{ TKMHouseArmorWorkshop }
constructor TKMHouseArmorWorkshop.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
begin
  inherited;

  fAcceptWood := True;
  fAcceptLeather := True;
end;


constructor TKMHouseArmorWorkshop.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('HouseArmorWorkshop');
  LoadStream.Read(fAcceptWood);
  LoadStream.Read(fAcceptLeather);
end;


procedure TKMHouseArmorWorkshop.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('HouseArmorWorkshop');
  SaveStream.Write(fAcceptWood);
  SaveStream.Write(fAcceptLeather);
end;


procedure TKMHouseArmorWorkshop.ToggleResDelivery(aWareType: TKMWareType);
begin
  case aWareType of
    wtTimber: fAcceptWood := not fAcceptWood;
    wtLeather: fAcceptLeather := not fAcceptLeather;
  end;
end;


function TKMHouseArmorWorkshop.AcceptWareForDelivery(aWareType: TKMWareType): Boolean;
begin
  Result := False;
  case aWareType of
    wtTimber: Result := fAcceptWood;
    wtLeather: Result := fAcceptLeather;
  end;
end;


function TKMHouseArmorWorkshop.ShouldAbandonDeliveryTo(aWareType: TKMWareType): Boolean;
begin
  Result := inherited or not AcceptWareForDelivery(aWareType);
end;


end.
