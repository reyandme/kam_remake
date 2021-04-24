unit KM_CommonClassesExt;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, TypInfo, Generics.Collections;

type
  ERuntimeTypeError = class(Exception);

  TSet<T> = class
  strict private
    class function TypeInfo: PTypeInfo; inline; static;
    class function GetSetToString(const PSet: PByteArray; const SizeOfSet(*in bytes*): Integer): String; static;
  public
    class function IsSet: Boolean; static;
    class function Cardinality(const Value: T): Integer; static;
    class function SetToString(const Value: T): String; static;
  end;

  // List with unique elements
  // Very slow implmentation because of 'Contains' - loop through all list when adding 1 element
  TKMListUnique<T> = class(TList<T>)
  public
    function Add(const Value: T): Integer; reintroduce;
  end;


  TKMWeightedList<T> = class(TList<T>)
    fWeight: array of Single;
  public
    procedure Add(const aValue: T; aWeight: Single); reintroduce;
    function GetWeightedRandom(out aValue: T): Boolean;
  end;

  TKMLimitedQueue<T> = class(TQueue<T>)
  private
    fMaxLength: Integer;
  public
    constructor Create(aMaxLength: Integer);

    property MaxLength: Integer read fMaxLength write fMaxLength;

    procedure EnqueueItem(const Value: T);
  end;

  TKMLimitedList<T> = class(TList<T>)
  private
    fMaxLength: Integer;
  public
    constructor Create(aMaxLength: Integer);

    property MaxLength: Integer read fMaxLength write fMaxLength;

    function Add(const Value: T): Integer;
    procedure Swap(const ValueFrom, ValueTo: T);

  end;


  function GetCardinality(const PSet: PByteArray; const SizeOfSet(*in bytes*): Integer): Integer; inline;


const
  Masks: array[0..7] of Byte = (1, 2, 4, 8, 16, 32, 64, 128);

implementation
uses
  KM_CommonUtils;


{ TSet<T>

  Usage: Writeln(TSet<SomeSet>.Cardinality(Value));

  taken from:
  https://stackoverflow.com/questions/34442102/how-can-i-get-the-number-of-elements-of-any-variable-of-type-set }
class function TSet<T>.TypeInfo: PTypeInfo;
begin
  Result := System.TypeInfo(T);
end;

class function TSet<T>.IsSet: Boolean;
begin
  Result := TypeInfo.Kind = tkSet;
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


class function TSet<T>.GetSetToString(const PSet: PByteArray; const SizeOfSet(*in bytes*): Integer): String;
var
  I, J: Integer;
  BaseType: PTypeInfo;
begin
  Result := '';

  BaseType := GetTypeData(TypeInfo).CompType{$IFDEF WDC}^{$ENDIF}; //FPC has PTypeInfo here, while WDC has PPTypeInfo

  for I := 0 to SizeOfSet - 1 do
    for J := 0 to 7 do
      if (PSet^[I] and Masks[J]) > 0 then
      begin
        if Result <> '' then
          Result := Result + ', ';
        {$IFDEF WDC}
        Result := Result + GetEnumName(BaseType, J + I*8);
        {$ENDIF}
        {$IFDEF FPC}
        if BaseType^.Kind = tkInteger then //For some reason FPC can't return EnumName, at least for tkInteger values
          Result := Result + IntToStr(J + I*8)
        else
          Result := Result + GetEnumName(BaseType, J + I*8);
        {$ENDIF}
      end;
  Result := '[' + Result + ']';
end;

class function TSet<T>.Cardinality(const Value: T): Integer;
var
  EnumTypeData: PTypeData;
begin
  if not IsSet then
    raise ERuntimeTypeError.Create('Invalid type in TSet<T>, T must be a set');
  Result := GetCardinality(PByteArray(@Value), SizeOf(Value));
end;


class function TSet<T>.SetToString(const Value: T): String;
var
  EnumTypeData: PTypeData;
begin
  if not IsSet then
    raise ERuntimeTypeError.Create('Invalid type in TSet<T>, T must be a set');

  Result := GetSetToString(PByteArray(@Value), SizeOf(Value));
end;


{ TKMListUnique<T> }
function TKMListUnique<T>.Add(const Value: T): Integer;
begin
  if Contains(Value) then Exit;

  inherited Add(Value);
end;


{ TKMWeightedList }
procedure TKMWeightedList<T>.Add(const aValue: T; aWeight: Single);
begin
  inherited Add(aValue);

  if Count >= Length(fWeight) then
    SetLength(fWeight, Count + 32);

  fWeight[Count - 1] := aWeight;
end;


function TKMWeightedList<T>.GetWeightedRandom(out aValue: T): Boolean;
var
  I: Integer;
  WeightsSum, Rnd: Extended;
begin
  Result := False;

  if Count = 0 then
    Exit;

  WeightsSum := 0;
  for I := 0 to Count - 1 do
    WeightsSum := WeightsSum + fWeight[I];

  Rnd := KaMRandomS1(WeightsSum, 'TKMWeightedList.GetWeightedRandom');

  for I := 0 to Count - 1 do
  begin
    if Rnd < fWeight[I] then
    begin
      aValue := Items[I];
      Exit(True);
    end;
    Rnd := Rnd - fWeight[I];
  end;
  Assert(False, 'Error getting weighted random');
end;


{ TKMLimitedQueue<T> }
constructor TKMLimitedQueue<T>.Create(aMaxLength: Integer);
begin
  inherited Create;

  fMaxLength := aMaxLength;
end;


procedure TKMLimitedQueue<T>.EnqueueItem(const Value: T);
begin
  inherited Enqueue(Value);

  if Count > fMaxLength then
    Dequeue;
end;


{ TKMLimitedList<T> }
constructor TKMLimitedList<T>.Create(aMaxLength: Integer);
begin
  inherited Create;

  fMaxLength := aMaxLength;
end;


function TKMLimitedList<T>.Add(const Value: T): Integer;
begin
  inherited Add(Value);

  if Count > fMaxLength then
    Delete(0); // Delete the oldest item
end;



procedure TKMLimitedList<T>.Swap(const ValueFrom, ValueTo: T);
var
  fromI, toI: Integer;
begin
  fromI := IndexOf(ValueFrom);
  toI := IndexOf(ValueTo);

  // Do not swap items, if not found any
  if (fromI = -1) or (toI = -1) then Exit;

  Items[toI] := ValueFrom;
  Items[fromI] := ValueTo;
end;


end.

