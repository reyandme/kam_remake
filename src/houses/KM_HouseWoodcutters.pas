unit KM_HouseWoodcutters;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses, KM_Points, KM_Defaults,
  KM_Houses,
  KM_ResTypes;
  
type
  //* Woodcutting mode
  TKMWoodcutterMode = (wmChopAndPlant, wmChop, wmPlant);

  TKMHouseWoodcutters = class(TKMHouseWFlagPoint)
  private
    fWoodcutterMode: TKMWoodcutterMode;
    fCuttingPoint: TKMPoint;
    procedure SetWoodcutterMode(aWoodcutterMode: TKMWoodcutterMode);
  protected
    procedure SetFlagPoint(aFlagPoint: TKMPoint); override;
    function GetMaxDistanceToPoint: Integer; override;
  public
    constructor Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
    constructor Load(LoadStream: TKMemoryStream); override;
    procedure Save(SaveStream: TKMemoryStream); override;

    function ObjToString(const aSeparator: string = '|'): string; override;

    property WoodcutterMode: TKMWoodcutterMode read fWoodcutterMode write SetWoodcutterMode;
  end;


implementation
uses
  SysUtils, TypInfo,
  KM_ScriptingEvents;


{ TKMHouseWoodcutters }
constructor TKMHouseWoodcutters.Create(aUID: Integer; aHouseType: TKMHouseType; PosX, PosY: Integer; aOwner: TKMHandID; aBuildState: TKMHouseBuildState);
begin
  inherited;

  WoodcutterMode := wmChopAndPlant;
end;


constructor TKMHouseWoodcutters.Load(LoadStream: TKMemoryStream);
begin
  inherited;

  LoadStream.CheckMarker('HouseWoodcutters');
  LoadStream.Read(fWoodcutterMode, SizeOf(fWoodcutterMode));
end;


procedure TKMHouseWoodcutters.Save(SaveStream: TKMemoryStream);
begin
  inherited;

  SaveStream.PlaceMarker('HouseWoodcutters');
  SaveStream.Write(fWoodcutterMode, SizeOf(fWoodcutterMode));
end;


function TKMHouseWoodcutters.GetMaxDistanceToPoint: Integer;
begin
  Result := MAX_WOODCUTTER_CUT_PNT_DISTANCE;
end;


procedure TKMHouseWoodcutters.SetFlagPoint(aFlagPoint: TKMPoint);
var
  oldFlagPoint: TKMPoint;
begin
  oldFlagPoint := FlagPoint;
  inherited;

  if not KMSamePoint(oldFlagPoint, fCuttingPoint) then
    ResourceDepleted := False; //Reset resource depleted msg, if player changed CuttingPoint
end;


procedure TKMHouseWoodcutters.SetWoodcutterMode(aWoodcutterMode: TKMWoodcutterMode);
var
  oldWoodcutterMode: TKMWoodcutterMode;
begin
  //If we're allowed to plant only again or chop only
  //we should reshow the depleted message if we are changed to cut and run out of trees
  if (fWoodcutterMode <> aWoodcutterMode)
    and (aWoodcutterMode in [wmChop, wmPlant]) then
    ResourceDepleted := False;

  oldWoodcutterMode := fWoodcutterMode;

  fWoodcutterMode := aWoodcutterMode;
  gScriptEvents.ProcWoodcuttersModeChanged(Self, oldWoodcutterMode, fWoodcutterMode);
end;


function TKMHouseWoodcutters.ObjToString(const aSeparator: string = '|'): string;
begin
  Result := inherited ObjToString(aSeparator) +
            Format('%sWoodcutterMode = %s', [aSeparator, GetEnumName(TypeInfo(TKMWoodcutterMode), Ord(fWoodcutterMode))]);
end;


end.
