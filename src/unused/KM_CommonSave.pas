unit KM_CommonSave;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils,
  KM_Points;

const
  OBJECT_SIZE = SizeOf(TObject);

type
  TKMSaveStreamFormat = (ssfBinary, ssfText);

  TKSaveStream = class(TMemoryStream)
  public
    // Assert savegame sections
    procedure CheckMarker(const aTitle: string); virtual; abstract;
    procedure PlaceMarker(const aTitle: string); virtual; abstract;

    procedure ReadANSI(out aValue: string); virtual; abstract;
    procedure WriteANSI(const aValue: string); virtual; abstract;

    //Ansistrings saved by PascalScript into savegame
    procedure ReadHugeString(out Value: AnsiString); overload;
    procedure WriteHugeString(const Value: AnsiString); overload;

//    {$IFDEF DESKTOP}
    //Legacy format for campaigns info, maxlength 65k ansichars
    procedure ReadA(out Value: AnsiString); reintroduce; overload; virtual; abstract;
    procedure WriteA(const Value: AnsiString); reintroduce; overload; virtual; abstract;
//    {$ENDIF}
//    {$IFDEF TABLET}
//    //Legacy format for campaigns info, maxlength 65k ansichars
//    procedure ReadA(out Value: string); reintroduce; overload; virtual; abstract;
//    procedure WriteA(const Value: string); reintroduce; overload; virtual; abstract;
//    {$ENDIF}

    // Unicode strings
    procedure ReadW(out Value: UnicodeString); reintroduce; overload; virtual; abstract;
    procedure WriteW(const Value: UnicodeString); reintroduce; overload; virtual; abstract;

    function Write(const Buffer; Count: Longint): Longint; overload; override;

    procedure Write(const Value: TKMDirection  ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMPoint      ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMPointW     ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMPointF     ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMPointDir   ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMRangeInt   ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMRangeSingle); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMRect       ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Single        ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Extended      ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Integer       ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Cardinal      ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Byte          ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Boolean       ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Word          ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: ShortInt      ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: SmallInt      ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TDateTime     ); reintroduce; overload; virtual; abstract;

    procedure Read(out Value: TKMDirection  ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMPoint      ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMPointW     ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMPointF     ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMPointDir   ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMRangeInt   ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMRangeSingle); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMRect       ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Single        ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Extended      ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Integer       ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Cardinal      ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Byte          ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Boolean       ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Word          ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: ShortInt      ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: SmallInt      ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TDateTime     ); reintroduce; overload; virtual; abstract;
  end;

  // Extended with custom Read/Write commands which accept various types without asking for their length
  TKMSaveStreamBinary = class(TKSaveStream)
  public
    // Assert savegame sections
    procedure CheckMarker(const aTitle: string); override;
    procedure PlaceMarker(const aTitle: string); override;

    procedure ReadANSI(out aValue: string); override;
    procedure WriteANSI(const aValue: string); override;

//    {$IFDEF DESKTOP}
    //Legacy format for campaigns info, maxlength 65k ansichars
    procedure ReadA(out Value: AnsiString); override;
    procedure WriteA(const Value: AnsiString); override;
//    {$ENDIF}
//    {$IFDEF TABLET}
//    //Legacy format for campaigns info, maxlength 65k ansichars
//    procedure ReadA(out Value: string); override;
//    procedure WriteA(const Value: string); override;
//    {$ENDIF}

    // Unicode strings
    procedure ReadW(out Value: UnicodeString); override;
    procedure WriteW(const Value: UnicodeString); override;

    function Write(const Buffer; Count: Longint): Longint; override;

    procedure Write(const Value: TKMDirection  ); override;
    procedure Write(const Value: TKMPoint      ); override;
    procedure Write(const Value: TKMPointW     ); override;
    procedure Write(const Value: TKMPointF     ); override;
    procedure Write(const Value: TKMPointDir   ); override;
    procedure Write(const Value: TKMRangeInt   ); override;
    procedure Write(const Value: TKMRangeSingle); override;
    procedure Write(const Value: TKMRect       ); override;
    procedure Write(const Value: Single        ); override;
    procedure Write(const Value: Extended      ); override;
    procedure Write(const Value: Integer       ); override;
    procedure Write(const Value: Cardinal      ); override;
    procedure Write(const Value: Byte          ); override;
    procedure Write(const Value: Boolean       ); override;
    procedure Write(const Value: Word          ); override;
    procedure Write(const Value: ShortInt      ); override;
    procedure Write(const Value: SmallInt      ); override;
    procedure Write(const Value: TDateTime     ); override;

    procedure Read(out Value: TKMDirection  ); override;
    procedure Read(out Value: TKMPoint      ); override;
    procedure Read(out Value: TKMPointW     ); override;
    procedure Read(out Value: TKMPointF     ); override;
    procedure Read(out Value: TKMPointDir   ); override;
    procedure Read(out Value: TKMRangeInt   ); override;
    procedure Read(out Value: TKMRangeSingle); override;
    procedure Read(out Value: TKMRect       ); override;
    procedure Read(out Value: Single        ); override;
    procedure Read(out Value: Extended      ); override;
    procedure Read(out Value: Integer       ); override;
    procedure Read(out Value: Cardinal      ); override;
    procedure Read(out Value: Byte          ); override;
    procedure Read(out Value: Boolean       ); override;
    procedure Read(out Value: Word          ); override;
    procedure Read(out Value: ShortInt      ); override;
    procedure Read(out Value: SmallInt      ); override;
    procedure Read(out Value: TDateTime     ); override;
  end;

  // Text writer
  TKMSaveStreamText = class(TKSaveStream)
  private
    fLastSection: string;
    procedure WriteText(const aString: string);
  public
    procedure PlaceMarker(const aTitle: string); override;

    procedure WriteANSI(const aValue: string); override;
    procedure WriteA(const Value: AnsiString); override;
    procedure WriteW(const Value: UnicodeString); override;

    function Write(const Buffer; Count: Longint): Longint; override;

    procedure Write(const Value: TKMDirection  ); override;
    procedure Write(const Value: TKMPoint      ); override;
    procedure Write(const Value: TKMPointW     ); override;
    procedure Write(const Value: TKMPointF     ); override;
    procedure Write(const Value: TKMPointDir   ); override;
    procedure Write(const Value: TKMRangeInt   ); override;
    procedure Write(const Value: TKMRangeSingle); override;
    procedure Write(const Value: TKMRect       ); override;
    procedure Write(const Value: Single        ); override;
    procedure Write(const Value: Extended      ); override;
    procedure Write(const Value: Integer       ); override;
    procedure Write(const Value: Cardinal      ); override;
    procedure Write(const Value: Byte          ); override;
    procedure Write(const Value: Boolean       ); override;
    procedure Write(const Value: Word          ); override;
    procedure Write(const Value: ShortInt      ); override;
    procedure Write(const Value: SmallInt      ); override;
    procedure Write(const Value: TDateTime     ); override;
  end;

  TStreamEvent = procedure (aData: TKSaveStream) of object;

implementation


function TKSaveStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result := inherited Write(Buffer, Count);
end;


procedure TKSaveStream.ReadHugeString(out Value: AnsiString);
var I: Cardinal;
begin
  Read(I, SizeOf(I));
  SetLength(Value, I);
  if I > 0 then
    Read(Pointer(Value)^, I);
end;

procedure TKSaveStream.WriteHugeString(const Value: AnsiString);
var I: Cardinal;
begin
  I := Length(Value);
  inherited Write(I, SizeOf(I));
  if I = 0 then Exit;
  inherited Write(Pointer(Value)^, I);
end;


{ TKMSaveStreamBinary }
procedure TKMSaveStreamBinary.CheckMarker(const aTitle: string);
var
  s: string;
begin
  // We use only Latin for Markers, hence ANSI is fine
  // But since Android does not support "AnsiString" we take "string" as input
  ReadANSI(s);
  Assert(s = aTitle);
end;


procedure TKMSaveStreamBinary.PlaceMarker(const aTitle: string);
begin
  // We use only Latin for Markers, hence ANSI is fine
  // But since Android does not support "AnsiString" we take "string" as input
  WriteANSI(aTitle);
end;


procedure TKMSaveStreamBinary.ReadANSI(out aValue: string);
var
  I: Word;
  bytes: TBytes;
begin
  aValue := '';
  inherited Read(I, SizeOf(I));
  SetLength(bytes, I);
  if I = 0 then Exit;
  inherited Read(bytes[0], I);
  aValue := TEncoding.ANSI.GetString(bytes);
end;


procedure TKMSaveStreamBinary.WriteANSI(const aValue: string);
var
  I: Word;
  bytes: TBytes;
begin
  bytes := TEncoding.ANSI.GetBytes(aValue);
  I := Length(bytes);
  Write(I, SizeOf(I));
  if I = 0 then Exit;
  Write(bytes[0], I);
end;


//{$IFDEF DESKTOP}
procedure TKMSaveStreamBinary.ReadA(out Value: AnsiString);
var I: Word;
begin
  Read(I, SizeOf(I));
  SetLength(Value, I);
  if I > 0 then
    Read(Pointer(Value)^, I);
end;

procedure TKMSaveStreamBinary.WriteA(const Value: AnsiString);
var I: Word;
begin
  I := Length(Value);
  inherited Write(I, SizeOf(I));
  if I = 0 then Exit;
  inherited Write(Pointer(Value)^, I);
end;
//{$ENDIF}


//{$IFDEF TABLET}
//procedure TKMemoryStream.ReadA(out Value: string);
//var I: Word;
//begin
//  Read(I, SizeOf(I));
//  SetLength(Value, I);
//  if I > 0 then
//    Read(Pointer(Value)^, I * SizeOf(WideChar));
//end;
//
//procedure TKMemoryStream.WriteA(const Value: string);
//var I: Word;
//begin
//  I := Length(Value);
//  inherited Write(I, SizeOf(I));
//  if I = 0 then Exit;
//  inherited Write(Pointer(Value)^, I * SizeOf(WideChar));
//end;
//{$ENDIF}


procedure TKMSaveStreamBinary.ReadW(out Value: UnicodeString);
var I: Word;
begin
  Read(I, SizeOf(I));
  SetLength(Value, I);
  if I > 0 then
    Read(Pointer(Value)^, I * SizeOf(WideChar));
end;


procedure TKMSaveStreamBinary.WriteW(const Value: UnicodeString);
var I: Word;
begin
  I := Length(Value);
  inherited Write(I, SizeOf(I));
  if I = 0 then Exit;
  inherited Write(Pointer(Value)^, I * SizeOf(WideChar));
end;

function TKMSaveStreamBinary.Write(const Buffer; Count: Longint): Longint;
begin
  Result := inherited Write(Buffer, Count);
end;

procedure TKMSaveStreamBinary.Read(out Value: TKMDirection);   begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: TKMPoint);       begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: TKMPointW);      begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: TKMPointF);      begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: TKMPointDir);    begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: TKMRangeInt);    begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: TKMRangeSingle); begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: TKMRect);        begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: Single);         begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: Extended);       begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: Integer);        begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: Cardinal);       begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: Byte);           begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: Boolean);        begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: Word);           begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: ShortInt);       begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: SmallInt);       begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Read(out Value: TDateTime);      begin inherited Read(Value, SizeOf(Value)); end;


procedure TKMSaveStreamBinary.Write(const Value: TKMDirection);   begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: TKMPoint);       begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: TKMPointW);      begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: TKMPointF);      begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: TKMPointDir);    begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: TKMRangeInt);    begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: TKMRangeSingle); begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: TKMRect);        begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: Single);         begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: Extended);       begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: Integer);        begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: Cardinal);       begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: Byte);           begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: Boolean);        begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: Word);           begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: ShortInt);       begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: SmallInt);       begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMSaveStreamBinary.Write(const Value: TDateTime);      begin inherited Write(Value, SizeOf(Value)); end;


{ TKMSaveStreamText }
procedure TKMSaveStreamText.WriteText(const aString: string);
var
  I: Word;
  bytes: TBytes;
begin
  bytes := TEncoding.ANSI.GetBytes(aString + ' ');

  I := Length(bytes);
  inherited Write(bytes[0], I);
end;

function TKMSaveStreamText.Write(const Buffer; Count: Longint): Longint;
begin
  if Count = 1 then
    WriteText(IntToHex(PByte(@Buffer)^, 2) + 'h')
  else
  if Count = 2 then
    WriteText(IntToHex(PWord(@Buffer)^, 4) + 'h')
  else
    WriteText(IntToStr(Count) + 'bytes');
  Result := -1;
end;

procedure TKMSaveStreamText.PlaceMarker(const aTitle: string);
begin
  fLastSection := aTitle;
  WriteText(sLineBreak + '[' + aTitle + ']' + sLineBreak);
end;

procedure TKMSaveStreamText.WriteA(const Value: AnsiString);
begin
  WriteText(UnicodeString(Value));
end;

procedure TKMSaveStreamText.WriteANSI(const aValue: string);
begin
  WriteText(aValue);
end;

procedure TKMSaveStreamText.WriteW(const Value: UnicodeString);
begin
  WriteText(Value);
end;

procedure TKMSaveStreamText.Write(const Value: TKMPointDir);
begin
  WriteText(Value.ToString);
end;

procedure TKMSaveStreamText.Write(const Value: TKMRangeInt);
begin
  WriteText(Value.ToString);
end;

procedure TKMSaveStreamText.Write(const Value: TKMRangeSingle);
begin
  WriteText(Value.ToString);
end;

procedure TKMSaveStreamText.Write(const Value: TKMRect);
begin
  WriteText(Value.ToString);
end;

procedure TKMSaveStreamText.Write(const Value: TKMDirection);
begin
  WriteText('Dir' + IntToStr(Ord(Value)));
end;

procedure TKMSaveStreamText.Write(const Value: TKMPoint);
begin
  WriteText(Value.ToString);
end;

procedure TKMSaveStreamText.Write(const Value: TKMPointW);
begin
  WriteText(Value.ToString);
end;

procedure TKMSaveStreamText.Write(const Value: TKMPointF);
begin
  WriteText(Value.ToString);
end;

procedure TKMSaveStreamText.Write(const Value: Boolean);
begin
  WriteText(BoolToStr(Value, True));
end;

procedure TKMSaveStreamText.Write(const Value: Word);
begin
  WriteText(IntToStr(Value));
end;

procedure TKMSaveStreamText.Write(const Value: ShortInt);
begin
  WriteText(IntToStr(Value));
end;

procedure TKMSaveStreamText.Write(const Value: SmallInt);
begin
  WriteText(IntToStr(Value));
end;

procedure TKMSaveStreamText.Write(const Value: Byte);
begin
  WriteText(IntToStr(Value));
end;

procedure TKMSaveStreamText.Write(const Value: Single);
begin
  WriteText(Format('%.5f', [Value]));
end;

procedure TKMSaveStreamText.Write(const Value: Extended);
begin
  WriteText(Format('%.5f', [Value]));
end;

procedure TKMSaveStreamText.Write(const Value: Integer);
begin
  WriteText(IntToStr(Value));
end;

procedure TKMSaveStreamText.Write(const Value: Cardinal);
begin
  WriteText(IntToStr(Value));
end;

procedure TKMSaveStreamText.Write(const Value: TDateTime);
var
  Str: String;
begin
  DateTimeToString(Str, 'dd.mm.yyyy hh:nn:ss.zzz', Value);
  WriteText(Str);
end;

end.
