unit KM_HouseWoodcutters;
{$I KaM_Remake.inc}
interface
uses
  KM_Houses, KM_ResHouses,
  KM_CommonClasses, KM_Points, KM_Defaults;
  
type
  TKMWoodcutterMode = (wcmChopAndPlant, wcmChop, wcmPlant);
  
  TKMHouseWoodcutters = class(TKMHouseWFlagPoint)
  private
    fWoodcutterMode: TKMWoodcutterMode;
    fCuttingPoint: TKMPoint;
    procedure SetWoodcutterMode(aWoodcutterMode: TKMWoodcutterMode);
  protected
    procedure SetFlagPoint(aFlagPoint: TKMPoint); override;
    function GetFlagPointTexId: Word; override;
    function GetMaxDistanceToPoint: Integer; override;
  public
    property WoodcutterMode: TKMWoodcutterMode read fWoodcutterMode write SetWoodcutterMode;
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;

  
implementation
uses
  KM_Terrain;

{ TKMHouseWoodcutters }
constructor TKMHouseWoodcutters.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
begin
  inherited;
  WoodcutterMode := wcmChopAndPlant;
end;


constructor TKMHouseWoodcutters.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fWoodcutterMode, SizeOf(fWoodcutterMode));
end;


procedure TKMHouseWoodcutters.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fWoodcutterMode, SizeOf(fWoodcutterMode));
end;


function TKMHouseWoodcutters.GetFlagPointTexId: Word;
begin
  Result := 660;
end;


function TKMHouseWoodcutters.GetMaxDistanceToPoint: Integer;
begin
  Result := MAX_WOODCUTTER_CUT_PNT_DISTANCE;
end;


procedure TKMHouseWoodcutters.SetFlagPoint(aFlagPoint: TKMPoint);
var
  OldFlagPoint: TKMPoint;
begin
  OldFlagPoint := FlagPoint;
  inherited;

  if not KMSamePoint(OldFlagPoint, fCuttingPoint) then
    ResourceDepletedMsgIssued := False; //Reset resource depleted msg, if player changed CuttingPoint
end;


procedure TKMHouseWoodcutters.SetWoodcutterMode(aWoodcutterMode: TKMWoodcutterMode);
begin
  //If we're allowed to plant only again or chop only
  //we should reshow the depleted message if we are changed to cut and run out of trees
  if (fWoodcutterMode <> aWoodcutterMode)
    and (aWoodcutterMode in [wcmChop, wcmPlant]) then
    ResourceDepletedMsgIssued := False;

  fWoodcutterMode := aWoodcutterMode;
end;


end.
