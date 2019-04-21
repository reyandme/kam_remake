unit KM_WareDistribution;
{$I KaM_Remake.inc}
interface
uses
  KM_ResWares, KM_ResHouses,
  KM_CommonClasses;


const
  //These have been adjusted slightly from the old KaM defaults.
  //The number means how many items should be in houses input max, and also affects delivery priority.
  DistributionDefaults: array [1..4, 1..4] of Byte = (
    (5, 5, 0, 0),
    (5, 3, 4, 4),
    (3, 4, 0, 0),
    (4, 5, 3, 0)
  );


type
  TKMWareDistribution = class
  private
    fWareDistribution: array [1..4, 1..4] of Byte;
    procedure SetWareDistribution(aWare: TKMWareType; aHouse: TKMHouseType; aValue: Byte);
    function GetWareDistribution(aWare: TKMWareType; aHouse: TKMHouseType): Byte;
  public
    Changed: Boolean;
    constructor Create;
    property WareDistribution[aWare: TKMWareType; aHouse: TKMHouseType]: Byte read GetWareDistribution write SetWareDistribution; default;
    procedure LoadFromStr(aString: String);
    function PackToStr: String;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
  end;


implementation
uses
  SysUtils, Math;

{TKMWareDistribution}
constructor TKMWareDistribution.Create;
var I, K: Integer;
begin
  for I := 1 to 4 do for K := 1 to 4 do
    fWareDistribution[I, K] := DistributionDefaults[I, K];  // Load default ratios
end;


procedure TKMWareDistribution.SetWareDistribution(aWare: TKMWareType; aHouse: TKMHouseType; aValue: Byte);
begin
  case aWare of
    wtSteel: if aHouse = htWeaponSmithy   then fWareDistribution[1,1] := aValue else
              if aHouse = htArmorSmithy    then fWareDistribution[1,2] := aValue;
    wtCoal:  if aHouse = htIronSmithy     then fWareDistribution[2,1] := aValue else
              if aHouse = htMetallurgists  then fWareDistribution[2,2] := aValue else
              if aHouse = htWeaponSmithy   then fWareDistribution[2,3] := aValue else
              if aHouse = htArmorSmithy    then fWareDistribution[2,4] := aValue;
    wtWood:  if aHouse = htArmorWorkshop  then fWareDistribution[3,1] := aValue else
              if aHouse = htWeaponWorkshop then fWareDistribution[3,2] := aValue;
    wtCorn:  if aHouse = htMill           then fWareDistribution[4,1] := aValue else
              if aHouse = htSwine          then fWareDistribution[4,2] := aValue else
              if aHouse = htStables        then fWareDistribution[4,3] := aValue;
    else      raise Exception.Create('Unexpected resource at SetWareDistribution');
  end;
  Changed := True;
end;


function TKMWareDistribution.GetWareDistribution(aWare: TKMWareType; aHouse: TKMHouseType): Byte;
begin
  Result := 5; //Default should be 5, for house/resource combinations that don't have a setting (on a side note this should be the only place the resourse limit is defined)
  case aWare of
    wtSteel: if aHouse = htWeaponSmithy   then Result := fWareDistribution[1,1] else
              if aHouse = htArmorSmithy    then Result := fWareDistribution[1,2];
    wtCoal:  if aHouse = htIronSmithy     then Result := fWareDistribution[2,1] else
              if aHouse = htMetallurgists  then Result := fWareDistribution[2,2] else
              if aHouse = htWeaponSmithy   then Result := fWareDistribution[2,3] else
              if aHouse = htArmorSmithy    then Result := fWareDistribution[2,4];
    wtWood:  if aHouse = htArmorWorkshop  then Result := fWareDistribution[3,1] else
              if aHouse = htWeaponWorkshop then Result := fWareDistribution[3,2];
    wtCorn:  if aHouse = htMill           then Result := fWareDistribution[4,1] else
              if aHouse = htSwine          then Result := fWareDistribution[4,2] else
              if aHouse = htStables        then Result := fWareDistribution[4,3];
    else      //Handled in 1st row to avoid repeating in if .. else lines
  end;
end;


procedure TKMWareDistribution.LoadFromStr(aString: String);
  function IsValid: Boolean;
  var I: Integer;
  begin
    Result := Length(aString) = 16; // Ware distribution string length should be equal to 16
    if Result then
      for I := 1 to 16 do
        begin
          Result := Result and InRange(Ord(aString[I]), 48, 53); //In ware distribution string only digits from 0 to 5 are allowed'
        end;

  end;
var I, J: Integer;
begin
  aString := Trim(aString); // Trim possible spaces
  //Distribution format is string of 16 digits, each digit should be between 0 and 5
  if IsValid then
    for I := 1 to 16 do
      fWareDistribution[1+((I-1) div 4), 1+((I-1) mod 4)] := StrToInt(aString[I])
  else
    for I := 1 to 4 do
      for J := 1 to 4 do
        fWareDistribution[I, J] := DistributionDefaults[I, J];
end;


function TKMWareDistribution.PackToStr: String;
var I, J: Integer;
begin
  Result := '';
  for I := 1 to 4 do
    for J := 1 to 4 do
      Result := Result + IntToStr(fWareDistribution[I, J]);
end;


procedure TKMWareDistribution.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fWareDistribution, SizeOf(fWareDistribution));
end;


procedure TKMWareDistribution.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(fWareDistribution, SizeOf(fWareDistribution));
end;


end.
