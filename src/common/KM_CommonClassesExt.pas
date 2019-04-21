unit KM_CommonClassesExt;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, TypInfo;

type
  ERuntimeTypeError = class(Exception);

  TSet<T> = class
  strict private
    class function TypeInfo: PTypeInfo; inline; static;
  public
    class function IsSet: Boolean; static;
    class function Cardinality(const Value: T): Integer; static;
  end;

const
  Masks: array[0..7] of Byte = (1, 2, 4, 8, 16, 32, 64, 128);

implementation


{ TSet<T>
  taken from there:
  Usage: Writeln(TSet<SomeSet>.Cardinality(Value));
  https://stackoverflow.com/questions/34442102/how-can-i-get-the-number-of-elements-of-any-variable-of-type-set }
class function TSet<T>.TypeInfo: PTypeInfo;
begin
  Result := System.TypeInfo(T);
end;

class function TSet<T>.IsSet: Boolean;
begin
  Result := TypeInfo.Kind=tkSet;
end;

function GetCardinality(const PSet: PByteArray; const SizeOfSet(*in bytes*): Integer): Integer; inline;
var
  I, J: Integer;
begin
  Result := 0;
  for I := 0 to SizeOfSet - 1 do
    for J := 0 to 7 do
      if (PSet^[I] and Masks[J]) > 0 then
        Inc(Result);
end;

class function TSet<T>.Cardinality(const Value: T): Integer;
var
  EnumTypeData: PTypeData;
begin
  if not IsSet then
    raise ERuntimeTypeError.Create('Invalid type in TSet<T>, T must be a set');
  Result := GetCardinality(PByteArray(@Value), SizeOf(Value));
end;

end.