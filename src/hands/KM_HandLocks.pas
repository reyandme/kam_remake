unit KM_HandLocks;
{$I KaM_Remake.inc}
interface
uses
  KM_ResHouses, KM_ResWares,
  KM_CommonClasses, KM_Defaults;


type
  // Permissions
  TKMHandLocks = class
  private
    fHouseUnlocked: array [THouseType] of Boolean; //If building requirements performed
    fUnitBlocked: array [TUnitType] of Boolean;   //Allowance derived from mission script
    fMilitiaBlockedInTH: Boolean; // special case for militia block to train in TownHall
    procedure UpdateReqDone(aType: THouseType);
  public
    HouseBlocked: array [THouseType] of Boolean; //Allowance derived from mission script
    HouseGranted: array [THouseType] of Boolean; //Allowance derived from mission script

    AllowToTrade: array [WARE_MIN..WARE_MAX] of Boolean; //Allowance derived from mission script
    constructor Create;

    procedure HouseCreated(aType: THouseType);
    function HouseCanBuild(aType: THouseType): Boolean;

    procedure SetUnitBlocked(aIsBlocked: Boolean; aUnitType: TUnitType; aInTownHall: Boolean = False);
    function GetUnitBlocked(aUnitType: TUnitType; aInTownHall: Boolean = False): Boolean;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
  end;


implementation
uses
  KM_Resource;


{ TKMHandLocks }
constructor TKMHandLocks.Create;
var
  W: TWareType;
begin
  inherited;

  for W := WARE_MIN to WARE_MAX do
    AllowToTrade[W] := True;

  //Release Store at the start of the game by default
  fHouseUnlocked[ht_Store] := True;
end;


procedure TKMHandLocks.UpdateReqDone(aType: THouseType);
var
  H: THouseType;
begin
  for H := HOUSE_MIN to HOUSE_MAX do
    if gRes.Houses[H].ReleasedBy = aType then
      fHouseUnlocked[H] := True;
end;


// New house, either built by player or created by mission script
procedure TKMHandLocks.HouseCreated(aType: THouseType);
begin
  UpdateReqDone(aType);
end;


// Get effective permission
function TKMHandLocks.HouseCanBuild(aType: THouseType): Boolean;
begin
  Result := (fHouseUnlocked[aType] or HouseGranted[aType]) and not HouseBlocked[aType];
end;


function TKMHandLocks.GetUnitBlocked(aUnitType: TUnitType; aInTownHall: Boolean = False): Boolean;
begin
  if aInTownHall and (aUnitType = ut_Militia) then
    Result := fMilitiaBlockedInTH
  else
    Result := fUnitBlocked[aUnitType];
end;


procedure TKMHandLocks.SetUnitBlocked(aIsBlocked: Boolean; aUnitType: TUnitType; aInTownHall: Boolean = False);
begin
  if aInTownHall and (aUnitType = ut_Militia) then
    fMilitiaBlockedInTH := aIsBlocked
  else
    fUnitBlocked[aUnitType] := aIsBlocked;
end;


procedure TKMHandLocks.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.WriteA('HandLocks');
  SaveStream.Write(HouseBlocked, SizeOf(HouseBlocked));
  SaveStream.Write(HouseGranted, SizeOf(HouseGranted));
  SaveStream.Write(fUnitBlocked, SizeOf(fUnitBlocked));
  SaveStream.Write(AllowToTrade, SizeOf(AllowToTrade));
  SaveStream.Write(fHouseUnlocked, SizeOf(fHouseUnlocked));
end;


procedure TKMHandLocks.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.ReadAssert('HandLocks');
  LoadStream.Read(HouseBlocked, SizeOf(HouseBlocked));
  LoadStream.Read(HouseGranted, SizeOf(HouseGranted));
  LoadStream.Read(fUnitBlocked, SizeOf(fUnitBlocked));
  LoadStream.Read(AllowToTrade, SizeOf(AllowToTrade));
  LoadStream.Read(fHouseUnlocked, SizeOf(fHouseUnlocked));
end;


end.
