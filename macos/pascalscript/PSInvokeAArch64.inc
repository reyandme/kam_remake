{ Free Pascal / AArch64 bridge. PascalScript records are packed; the records
  exported by KaM contain integer fields, so describe their exact byte layout
  instead of imposing C structure padding. Managed results use FPC's explicit
  result argument, immediately after Self. }
function TPSExec.InnerfuseCall(_Self, Address: Pointer; CallingConv: TPSCallingConvention;
  Params: TPSList; res: PPSVariantIFC): Boolean;
type
  TBlob = record
    Info: ffi_type;
    Elements: array of pffi_type;
  end;
var
  Types: array of pffi_type;
  Values, PointerSlots: array of Pointer;
  HighSlots: array of PtrInt;
  Blobs: array of TBlob;
  ReturnBuffer: array of Byte;
  CIF: ffi_cif;
  ReturnType: pffi_type;
  V: PPSVariantIFC;
  I, N, BlobCount, ReturnSize: Integer;
  ManagedResult: Boolean;

  function BlobType(T: TPSTypeRec): pffi_type;
  var J, B: Integer;
  begin
    B := BlobCount;
    Inc(BlobCount);
    SetLength(Blobs[B].Elements, T.RealSize + 1);
    for J := 0 to T.RealSize - 1 do Blobs[B].Elements[J] := @ffi_type_uint8;
    Blobs[B].Elements[T.RealSize] := nil;
    Blobs[B].Info.size := T.RealSize;
    Blobs[B].Info.alignment := 1;
    if SameText(string(T.ExportName), 'TKMPOINT') then Blobs[B].Info.alignment := 4;
    Blobs[B].Info._type := _FFI_TYPE_STRUCT;
    Blobs[B].Info.elements := @Blobs[B].Elements[0];
    Result := @Blobs[B].Info;
  end;

  function NativeType(T: TPSTypeRec): pffi_type;
  begin
    case T.BaseType of
      btU8, btChar: Result := @ffi_type_uint8;
      btS8: Result := @ffi_type_sint8;
      btU16, btWideChar: Result := @ffi_type_uint16;
      btS16: Result := @ffi_type_sint16;
      btU32: Result := @ffi_type_uint32;
      btS32: Result := @ffi_type_sint32;
      btS64, btCurrency: Result := @ffi_type_sint64;
      btSingle: Result := @ffi_type_float;
      btDouble, btExtended: Result := @ffi_type_double;
      btString, btUnicodeString, btWideString, btPChar, btClass, btArray,
      btInterface, btStaticArray: Result := @ffi_type_pointer;
      btRecord: Result := BlobType(T);
      btSet:
        case TPSTypeRec_Set(T).aByteSize of
          1: Result := @ffi_type_uint8;
          2: Result := @ffi_type_uint16;
          4: Result := @ffi_type_uint32;
          else Result := BlobType(T);
        end;
      else raise Exception.CreateFmt('Unsupported ARM64 script type: %s (%d)',
        [string(T.ExportName), T.BaseType]);
    end;
  end;

  procedure AddValue(T: pffi_type; P: Pointer);
  begin
    Types[N] := T;
    Values[N] := P;
    Inc(N);
  end;

  procedure AddPointer(P: Pointer);
  begin
    PointerSlots[N] := P;
    AddValue(@ffi_type_pointer, @PointerSlots[N]);
  end;

begin
  Result := False;
  SetLength(Types, Params.Count * 2 + 3);
  SetLength(Values, Length(Types));
  SetLength(PointerSlots, Length(Types));
  SetLength(HighSlots, Length(Types));
  SetLength(Blobs, Params.Count + 1);
  N := 0;
  BlobCount := 0;
  if _Self <> nil then AddPointer(_Self);
  ManagedResult := Assigned(res) and
    (res.aType.BaseType in [btString, btUnicodeString, btWideString, btArray, btInterface]);
  ReturnSize := 0;
  ReturnType := @ffi_type_void;
  if Assigned(res) then
  begin
    if ManagedResult then
    begin
      FinalizeVariant(res.dta, res.aType);
      InitializeVariant(res.dta, res.aType);
      AddPointer(res.dta);
    end
    else
    begin
      ReturnType := NativeType(res.aType);
      ReturnSize := res.aType.RealSize;
    end;
  end;
  for I := 0 to Params.Count - 1 do
  begin
    V := Params[I];
    if V = nil then Exit;
    if V.varparam or (V.aType.BaseType in [btVariant, btStaticArray]) then
      AddPointer(V.dta)
    else if (V.aType.BaseType = btArray) and
      (Copy(V.aType.ExportName, 1, 10) = '!OPENARRAY') then
    begin
      AddValue(@ffi_type_pointer, V.dta);
      HighSlots[N] := PSDynArrayGetLength(PPointer(V.dta)^, V.aType) - 1;
      AddValue(@ffi_type_sint64, @HighSlots[N]);
    end
    else
      AddValue(NativeType(V.aType), V.dta);
  end;
  FillChar(CIF, SizeOf(CIF), 0);
  if ffi_prep_cif(@CIF, FFI_DEFAULT_ABI, N, ReturnType, @Types[0]) <> FFI_OK then
    raise Exception.Create('Could not prepare ARM64 script call');
  SetLength(ReturnBuffer, Max(ReturnSize, SizeOf(ffi_arg)));
  ffi_call(@CIF, ffi_fn(Address), @ReturnBuffer[0], @Values[0]);
  if ReturnSize > 0 then Move(ReturnBuffer[0], res.dta^, ReturnSize);
  Result := True;
end;
