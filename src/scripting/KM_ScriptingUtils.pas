unit KM_ScriptingUtils;
{$I KaM_Remake.inc}

interface
uses
  Math, StrUtils, SysUtils,
  KM_ScriptingEvents, KM_CommonTypes, KM_Points;

type
  TKMScriptUtils = class(TKMScriptEntity)
  public
    function AbsI(aValue: Integer): Integer;
    function AbsS(aValue: Single): Single;

    function ArrayElementCount(const aElement: AnsiString; aArray: array of String): Integer;
    function ArrayElementCountB(aElement: Boolean; aArray: array of Boolean): Integer;
    function ArrayElementCountI(aElement: Integer; aArray: array of Integer): Integer;
    function ArrayElementCountS(aElement: Single; aArray: array of Single): Integer;

    function ArrayHasElement(const aElement: AnsiString; aArray: array of String): Boolean;
    function ArrayHasElementB(aElement: Boolean; aArray: array of Boolean): Boolean;
    function ArrayHasElementI(aElement: Integer; aArray: array of Integer): Boolean;
    function ArrayHasElementS(aElement: Single; aArray: array of Single): Boolean;

    function ArrayRemoveIndexI(aIndex: Integer; aArray: TIntegerArray): TIntegerArray;
    function ArrayRemoveIndexS(aIndex: Integer; aArray: TAnsiStringArray): TAnsiStringArray;

    function BoolToStr(aBool: Boolean): AnsiString;

    function ColorBrightness(const aHexColor: string): Single;

    function CompareString(const Str1, Str2: String): Integer;
    function CompareText(const Str1, Str2: String): Integer;
    function CopyString(Str: String; Index, Count: Integer): String;

    procedure DeleteString(var Str: String; Index, Count: Integer);

    function EnsureRangeI(aValue, aMin, aMax: Integer): Integer;
    function EnsureRangeS(aValue, aMin, aMax: Single): Single;

    function Format(const aFormatting: string; aData: array of const): string;
    function FormatFloat(const aFormat: string; aValue: Single): string;

    function IfThen(aBool: Boolean; const aTrue, aFalse: AnsiString): AnsiString;
    function IfThenI(aBool: Boolean; aTrue, aFalse: Integer): Integer;
    function IfThenS(aBool: Boolean; aTrue, aFalse: Single): Single;

    function InAreaI(aX, aY, aXMin, aYMin, aXMax, aYMax: Integer): Boolean;
    function InAreaS(aX, aY, aXMin, aYMin, aXMax, aYMax: Single): Boolean;

    function InRangeI(aValue, aMin, aMax: Integer): Boolean;
    function InRangeS(aValue, aMin, aMax: Single): Boolean;

    procedure InsertString(Source: String; var Target: String; Index: Integer);

    function KMPoint(X,Y: Integer): TKMPoint;

    function Ln(const X: Extended): Extended;
    function Log2(const X: Extended): Extended;
    function Log10(const X: Extended): Extended;
    function LogN(const Base, X: Extended): Extended;

    function LowerCase(const Str: String): String;

    function MaxI(A, B: Integer): Integer;
    function MaxS(A, B: Single): Single;

    function MaxInArrayI(aArray: array of Integer): Integer;
    function MaxInArrayS(aArray: array of Single): Single;

    function MinI(A, B: Integer): Integer;
    function MinS(A, B: Single): Single;

    function MinInArrayI(aArray: array of Integer): Integer;
    function MinInArrayS(aArray: array of Single): Single;

    procedure MoveString(const Source: String; var Destination: String; Count: Integer);

    function Pos(SubStr, Str: String): Integer;

    function Power(aBase, aExp: Extended): Extended;

    function RandomRangeI(aFrom, aTo: Integer): Integer;

    function RGBDecToBGRHex(aR, aG, aB: Byte): AnsiString;
    function RGBToBGRHex(const aHexColor: string): AnsiString;

    function CeilTo(aValue: Single; aBase: Integer): Integer;
    function FloorTo(aValue: Single; aBase: Integer): Integer;
    function RoundTo(aValue: Single; aBase: Integer): Integer;
    function TruncTo(aValue: Single; aBase: Integer): Integer;

    function Sqr(A: Extended): Extended;

    function StringReplace(const Str, OldPattern, NewPattern: string; aReplaceAll, aIgnoreCase: Boolean): String;

    function SumI(aArray: array of Integer): Integer;
    function SumS(aArray: array of Single): Single;

    function TimeToString(aTicks: Integer): AnsiString;
    function TimeToTick(aHours, aMinutes, aSeconds: Integer): Cardinal;

    function Trim(const Str: String): String;
    function TrimLeft(const Str: String): String;
    function TrimRight(const Str: String): String;

    function UpperCase(const Str: String): String;
  end;


implementation
uses
  KM_CommonUtils;


function TryParseHexColor(aHexColor: string; out aResult: string): Boolean;
begin
  aHexColor := UpperCase(aHexColor);
  if aHexColor[1] <> '$' then
  begin
    if Length(aHexColor) = 6 then
      aResult := '$' + aHexColor
    else if Length(aHexColor) = 7 then
      aResult := '$' + Copy(aHexColor, 2, Length(aHexColor))
    else
      aResult := '';

    Result := Length(aResult) > 0;
  end else begin
    aResult := aHexColor;
    Result := Length(aHexColor) = 7;
  end;
end;


{ TKMScriptingUtils }

//* Version: 7000+
//* Returns absolute value of specified integer
function TKMScriptUtils.AbsI(aValue: Integer): Integer;
begin
  try
    Result := System.Abs(aValue);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns absolute value of specified single number
function TKMScriptUtils.AbsS(aValue: Single): Single;
begin
  try
    Result := System.Abs(aValue);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Checks how many times specified string comes in requested array
function TKMScriptUtils.ArrayElementCount(const aElement: AnsiString; aArray: array of String): Integer;
var
  I: Integer;
begin
  Result := 0;
  try
    if Length(aArray) > 0 then
    begin
      for I := 0 to High(aArray) do
        if aArray[I] = String(aElement) then
          Inc(Result);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Checks how many times specified boolean comes in requested array
function TKMScriptUtils.ArrayElementCountB(aElement: Boolean; aArray: array of Boolean): Integer;
var
  I: Integer;
begin
  Result := 0;
  try
    if Length(aArray) > 0 then
    begin
      for I := 0 to High(aArray) do
        if aArray[I] = aElement then
          Inc(Result);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Checks how many times specified integer comes in requested array
function TKMScriptUtils.ArrayElementCountI(aElement: Integer; aArray: array of Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  try
    if Length(aArray) > 0 then
    begin
      for I := 0 to High(aArray) do
        if aArray[I] = aElement then
          Inc(Result);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Checks how many times specified single comes in requested array
function TKMScriptUtils.ArrayElementCountS(aElement: Single; aArray: array of Single): Integer;
var
  I: Integer;
begin
  Result := 0;
  try
    if Length(aArray) > 0 then
    begin
      for I := 0 to High(aArray) do
        if aArray[I] = aElement then
          Inc(Result);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Checks whether requested array has specified string
function TKMScriptUtils.ArrayHasElement(const aElement: AnsiString; aArray: array of String): Boolean;
var
  I: Integer;
begin
  Result := False;
  try
    if Length(aArray) > 0 then
    begin
      for I := 0 to High(aArray) do
        if aArray[I] = String(aElement) then
          Exit(True);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Checks whether requested array has specified boolean
function TKMScriptUtils.ArrayHasElementB(aElement: Boolean; aArray: array of Boolean): Boolean;
var
  I: Integer;
begin
  Result := False;
  try
    if Length(aArray) > 0 then
    begin
      for I := 0 to High(aArray) do
        if aArray[I] = aElement then
          Exit(True);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Checks whether requested array has specified integer
function TKMScriptUtils.ArrayHasElementI(aElement: Integer; aArray: array of Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  try
    if Length(aArray) > 0 then
    begin
      for I := 0 to High(aArray) do
        if aArray[I] = aElement then
          Exit(True);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Checks whether requested array has specified single number
function TKMScriptUtils.ArrayHasElementS(aElement: Single; aArray: array of Single): Boolean;
var
  I: Integer;
begin
  Result := False;
  try
    if Length(aArray) > 0 then
    begin
      for I := 0 to High(aArray) do
        if aArray[I] = aElement then
          Exit(True);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Removes element on specified index in specified array of integer.
//* Integer array should be declared as TIntegerArray instead of array of integer.
function TKMScriptUtils.ArrayRemoveIndexI(aIndex: Integer; aArray: TIntegerArray): TIntegerArray;
begin
  Result := aArray;
  try
    if (Length(aArray) > 0) and InRange(aIndex, Low(aArray), High(aArray)) then
    begin
      DeleteFromArray(aArray, aIndex);
      Result := aArray;
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Removes element on specified index in specified array of string.
//* String array should be declared as TAnsiStringArray instead of array of AnsiString.
function TKMScriptUtils.ArrayRemoveIndexS(aIndex: Integer; aArray: TAnsiStringArray): TAnsiStringArray;
begin
  Result := aArray;
  try
    if (Length(aArray) > 0) and InRange(aIndex, Low(aArray), High(aArray)) then
    begin
      DeleteFromArray(aArray, aIndex);
      Result := aArray;
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Return string representation of Boolean value: 'True' or 'False'
function TKMScriptUtils.BoolToStr(aBool: Boolean): AnsiString;
begin
  try
    Result := AnsiString(SysUtils.BoolToStr(aBool, True));
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 10940
//* Get Color Brightness from HEX BGR color
//* Result: Color Brightness OR -1 if aHexColor not equal to HEX BGR
function TKMScriptUtils.ColorBrightness(const aHexColor: string): Single;
var
  hexclr: String;
  Val: Integer;
begin
  try
    if TryParseHexColor(aHexColor, hexclr) and (TryStrToInt(hexclr, Val)) then
      Result := GetColorBrightness(Val)
    else
      Result := -1;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11750
//* Compares Str1 to Str2, with case-sensitivity.
//* Result: The return value is less than 0 if Str1 is less than Str2, 0 if Str1 equals Str2, or greater than 0 if Str1 is greater than Str2.
function TKMScriptUtils.CompareString(const Str1, Str2: String): Integer;
begin
  try
    Result := SysUtils.AnsiCompareStr(Str1, Str2);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11750
//* Compares Str1 to Str2, without case-sensitivity.
//* Result: The return value is less than 0 if Str1 is less than Str2, 0 if Str1 equals Str2, or greater than 0 if Str1 is greater than Str2.
function TKMScriptUtils.CompareText(const Str1, Str2: String): Integer;
begin
  try
    Result := SysUtils.AnsiCompareText(Str1, Str2);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11750
//* Creates a copy of part of a string
//* Result: Copy of part of a Str string
//* The first character of a string has index = 1.
//* Up to Count characters are copied from the Index of the Str string to the returned string.
//* Less than Count characters will be copied, if the end of the Str string is encountered before Count characters.
function TKMScriptUtils.CopyString(Str: String; Index, Count: Integer): String;
begin
  try
    Result := System.Copy(Str, Index, Count);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11750
//* Deletes up to Count characters from the Str string starting from position Index
//* The first character of a string has index = 1.
//* If the Index is before the first, or after the last character of Str, then no characters are deleted
//* No error is produced if Count exceeds the remaining character count of Str.
procedure TKMScriptUtils.DeleteString(var Str: String; Index, Count: Integer);
begin
  try
    System.Delete(Str, Index, Count);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns the closest to aValue integer that is in interval [aMin..aMax]
function TKMScriptUtils.EnsureRangeI(aValue, aMin, aMax: Integer): Integer;
begin
  try
    Result := Math.EnsureRange(aValue, aMin, aMax);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns the closest to aValue single number that is in interval [aMin..aMax]
function TKMScriptUtils.EnsureRangeS(aValue, aMin, aMax: Single): Single;
begin
  try
    Result := Math.EnsureRange(aValue, aMin, aMax);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Wrapper for pascal Format function
//* Formats aFormatting string with specified aData array of parameters
function TKMScriptUtils.Format(const aFormatting: string; aData: array of const): string;
begin
  try
    try
      Result := SysUtils.Format(aFormatting, aData);
    except
      //Format may throw an exception
      on E: EConvertError do
        LogParamWarn('Utils.Format: EConvertError: ' + E.Message, [aFormatting], aData);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11000
//* Wrapper for pascal FormatFloat function
//* Formats aValue with specified aFormat
function TKMScriptUtils.FormatFloat(const aFormat: string; aValue: Single): string;
begin
  try
    try
      Result := SysUtils.FormatFloat(aFormat, aValue);
    except
      //Format may throw an exception
      on E: EConvertError do
        LogParamWarn('Utils.FormatFloat: EConvertError: ' + E.Message, [aFormat, aValue]);
    end;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Checks condition aBool and returns aTrue/aFalse string depending on check result
function TKMScriptUtils.IfThen(aBool: Boolean; const aTrue, aFalse: AnsiString): AnsiString;
begin
  try
    if aBool then
      Result := aTrue
    else
      Result := aFalse;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Checks condition aBool and returns aTrue/aFalse integer depending on check result
function TKMScriptUtils.IfThenI(aBool: Boolean; aTrue, aFalse: Integer): Integer;
begin
  try
    Result := Math.IfThen(aBool, aTrue, aFalse);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Checks condition aBool and returns aTrue/aFalse single number depending on check result
function TKMScriptUtils.IfThenS(aBool: Boolean; aTrue, aFalse: Single): Single;
begin
  try
    Result := Math.IfThen(aBool, aTrue, aFalse);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* 2D variant of InRange, can be used for unit locs checks
function TKMScriptUtils.InAreaI(aX, aY, aXMin, aYMin, aXMax, aYMax: Integer): Boolean;
begin
  try
    Result := (Math.InRange(aX, aXMin, aXMax)) and Math.InRange(aY, aYMin, aYMax);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* 2D variant of InRange
function TKMScriptUtils.InAreaS(aX, aY, aXMin, aYMin, aXMax, aYMax: Single): Boolean;
begin
  try
    Result := (Math.InRange(aX, aXMin, aXMax)) and Math.InRange(aY, aYMin, aYMax);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Checks whether specified aValue is in interval [aMin..aMax]
function TKMScriptUtils.InRangeI(aValue, aMin, aMax: Integer): Boolean;
begin
  try
    Result := Math.InRange(aValue, aMin, aMax);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Checks whether specified aValue is in interval [aMin..aMax]
function TKMScriptUtils.InRangeS(aValue, aMin, aMax: Single): Boolean;
begin
  try
    Result := Math.InRange(aValue, aMin, aMax);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11750
//* Inserts one string, Source into another string, Target at the given position Index.
//* The first character of a string has index = 1.
//* The Target string characters from the Index character are moved right to make way for the Source string.
//* The length of Target string is now the sum of the length of the two strings.
//* To insert into the start of Target, set Index to 1 or less.
//* To append to the end of Target, set Index after the last character of Target.
procedure TKMScriptUtils.InsertString(Source: String; var Target: String; Index: Integer);
begin
  try
    System.Insert(Source, Target, Index);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns point record with specified coordinates
function TKMScriptUtils.KMPoint(X,Y: Integer): TKMPoint;
begin
  Result := TKMPoint.New(X,Y);
end;


//* Version: 15000
//* Returns the natural logarithm of X
function TKMScriptUtils.Ln(const X: Extended): Extended;
begin
  try
    Result := System.Ln(X);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 15000
//* Returns log of X for a base of 10
function TKMScriptUtils.Log10(const X: Extended): Extended;
begin
  try
    Result := Math.Log10(X);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 15000
//* Returns log of X for a base of 2
function TKMScriptUtils.Log2(const X: Extended): Extended;
begin
  try
    Result := Math.Log2(X);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 15000
//* Returns log of X for a specified base
function TKMScriptUtils.LogN(const Base, X: Extended): Extended;
begin
  try
    Result := Math.LogN(Base, X);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11750
//* Changes upper case characters in a string Str to lower case
function TKMScriptUtils.LowerCase(const Str: String): String;
begin
  try
    Result := SysUtils.AnsiLowerCase(Str);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns max number of two specified
function TKMScriptUtils.MaxI(A, B: Integer): Integer;
begin
  try
    Result := Math.Max(A, B);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns max number of two specified
function TKMScriptUtils.MaxS(A, B: Single): Single;
begin
  try
    Result := Math.Max(A, B);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns max number of array elements
function TKMScriptUtils.MaxInArrayI(aArray: array of Integer): Integer;
var
  I: Integer;
begin
  try
    Result := -MaxInt;
    if Length(aArray) > 0 then
    begin
      for I := 0 to High(aArray) do
        if aArray[I] > Result then
          Result := aArray[I];
    end
    else
      LogIntParamWarn('Utils.MaxInArrayI: Requested array is empty',[]);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns max number of array elements
function TKMScriptUtils.MaxInArrayS(aArray: array of Single): Single;
var
  I: Integer;
begin
  try
    Result := MinSingle;
    if Length(aArray) > 0 then
    begin
      for I := 0 to High(aArray) do
        if aArray[I] > Result then
          Result := aArray[I];
    end
    else
      LogIntParamWarn('Utils.MaxInArrayS: Requested array is empty',[]);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns min number of two specified
function TKMScriptUtils.MinI(A, B: Integer): Integer;
begin
  try
    Result := Math.Min(A, B);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns min number of two specified
function TKMScriptUtils.MinS(A, B: Single): Single;
begin
  try
    Result := Math.Min(A, B);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns min number of array elements
function TKMScriptUtils.MinInArrayI(aArray: array of Integer): Integer;
var
  I: Integer;
begin
  try
    Result := MaxInt;
    if Length(aArray) > 0 then
    begin
      for I := 0 to High(aArray) do
        if aArray[I] < Result then
          Result := aArray[I];
    end
    else
      LogIntParamWarn('Utils.MinInArrayI: Requested array is empty',[]);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns min number of array elements
function TKMScriptUtils.MinInArrayS(aArray: array of Single): Single;
var
  I: Integer;
begin
  try
    Result := MaxSingle;
    if Length(aArray) > 0 then
    begin
      for I := 0 to High(aArray) do
        if aArray[I] < Result then
          Result := aArray[I];
    end
    else
      LogIntParamWarn('Utils.MinInArrayS: Requested array is empty',[]);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11750
//* Copy data from a Source to a Destination
//* Count characters are copied from storage referenced by Source and written to Destination
//* It can be used to take a copy of a substring from one string and overlay it on top of part of another string.
procedure TKMScriptUtils.MoveString(const Source: String; var Destination: String; Count: Integer);
begin
  try
    System.Move(Source, Destination, Count);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11750
//* Searches for a substring, SubStr, in a string, Str.
//* Returns an integer value that is the index of the first character of SubStr within Str.
//* Function is case-sensitive.
//* If SubStr is not found, Result = 0
function TKMScriptUtils.Pos(SubStr, Str: String): Integer;
begin
  try
    Result := SysUtils.AnsiPos(SubStr, Str);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Exponentation, base 'Base' raised to power 'Exp'.
//* F.e. Power(3, 2) = 3^2 = 9
//* Returns base "Base" raised to power "Exp"
function TKMScriptUtils.Power(aBase, aExp: Extended): Extended;
begin
  try
    Result := Math.Power(aBase, aExp);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11000
//* Generates a random number in requested range aFrom..aTo (inclusive)
function TKMScriptUtils.RandomRangeI(aFrom, aTo: Integer): Integer;
begin
  try
    Result := KaMRandom(aTo - aFrom + 1{$IFDEF DBG_RNG_SPY}, 'TKMScriptUtils.RandomRangeI'{$ENDIF}) + aFrom;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 10940
//* Converts RGB to HEX BGR color
//* Result: HEX BGR Color
//* Example
//* VAR := RGBDecToBGRHex(255, 255, 0);
//* The result of the VAR will be 00FFFF
function TKMScriptUtils.RGBDecToBGRHex(aR, aG, aB: Byte): AnsiString;
begin
  try
    Result := AnsiString(Format('%.6x', [RGB2BGR(StrToInt('$' + IntToHex(aR, 2) + IntToHex(aG, 2) + IntToHex(aB, 2)))]));
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 10940
//* Converts HEX RGB to HEX BGR color
//* Result: HEX BGR Color or '' if aHexColor not equal to HEX RGB
//* Example
//* VAR := RGBToBGRHex('#FFFF00');
//* The result of the VAR will be 00FFFF
function TKMScriptUtils.RGBToBGRHex(const aHexColor: string): AnsiString;
var
  hexclr: String;
  Val: Integer;
begin
  try
    if TryParseHexColor(aHexColor, hexclr) and TryStrToInt(hexclr, Val) then
      Result := AnsiString(Format('%.6x', [RGB2BGR(Val)]))
    else
      Result := '';
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Rounds specified single number aValue to nearest multiple of specified base aBase. Rounding up.
//* F.e. CeilTo(11.7, 5) = 15 while CeilTo(-11.7, 5) = -10
function TKMScriptUtils.CeilTo(aValue: Single; aBase: Integer): Integer;
begin
  try
    Result := Ceil(aValue / aBase) * aBase
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Rounds specified single number aValue to nearest multiple of specified base aBase. Rounding down.
//* F.e. FloorTo(11.7, 5) = 10 while FloorTo(-11.7, 5) = -15
function TKMScriptUtils.FloorTo(aValue: Single; aBase: Integer): Integer;
begin
  try
    Result := Floor(aValue / aBase) * aBase
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 12400+
//* Rounds specified single number aValue to nearest multiple of specified base aBase. Rounding to the nearest integer.
//* If the number is exactly midway between two integers, then it rounds towards the even one (multiplied on aBase).
//* F.e. RoundTo(11.7, 5) = 10 while RoundTo(-11.7, 5) = -10
//* RoundTo(12.5, 5) = 10 while RoundTo(17.5, 5) = 20
function TKMScriptUtils.RoundTo(aValue: Single; aBase: Integer): Integer;
begin
  try
    Result := Round(aValue / aBase) * aBase
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 12400+
//* Rounds specified single number aValue to nearest multiple of specified base aBase. Rounding to zero.
//* F.e. TruncTo(11.7, 5) = 10 while TruncTo(-11.7, 5) = -10
function TKMScriptUtils.TruncTo(aValue: Single; aBase: Integer): Integer;
begin
  try
    Result := Trunc(aValue / aBase) * aBase
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns A^2 = A*A
function TKMScriptUtils.Sqr(A: Extended): Extended;
begin
  try
    Result := System.Sqr(A);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11750
//* Replaces the first or all occurences of a substring OldPattern in Str string with NewPattern according to additional settings
//* The changed string is returned as Result
//* The settings may be none, one, or both of these values:
//* aReplaceAll: Change all occurrences
//* aIgnoreCase: Ignore case when searching
function TKMScriptUtils.StringReplace(const Str, OldPattern, NewPattern: String; aReplaceAll, aIgnoreCase: Boolean): String;
var
  flags: TReplaceFlags;
begin
  try
    flags := [];
    if aReplaceAll then
      flags := flags + [rfReplaceAll];

    if aIgnoreCase then
      flags := flags + [rfIgnoreCase];

    Result := SysUtils.StringReplace(Str, OldPattern, NewPattern, flags);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns sum of the elements of requested array
function TKMScriptUtils.SumI(aArray: array of Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  try
    if Length(aArray) > 0 then
      for I := 0 to High(aArray) do
        Result := Result + aArray[I]
    else
      LogIntParamWarn('Utils.SumI: Requested array is empty',[]);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Returns sum of the elements of requested array
function TKMScriptUtils.SumS(aArray: array of Single): Single;
begin
  Result := 0;
  try
    if Length(aArray) > 0 then
      Result := Math.Sum(aArray)
    else
      LogIntParamWarn('Utils.SumS: Requested array is empty',[]);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 7000+
//* Converts game ticks count into string: HH:MM:SS
//* Can be used for scripted timers
function TKMScriptUtils.TimeToString(aTicks: Integer): AnsiString;
var
  H, M, S: Integer;
begin
  try
    if aTicks >= 0 then
    begin
      H := aTicks div 36000;
      M := (aTicks div 600) mod 60;
      S := (aTicks div 10) mod 60;
      Result := AnsiString(Format('%.2d:%.2d:%.2d', [H, M, S]));
    end
    else
      Result := '';
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 10940
//* Converts Time in game ticks
//* Result: game ticks
function TKMScriptUtils.TimeToTick(aHours, aMinutes, aSeconds: Integer): Cardinal;
begin
  try
    Result := ((aHours * 60 * 60) + (aMinutes * 60) + aSeconds) * 10;
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11750
//* Removes blank and control characters (such as line feed) from the start and end of a string.
function TKMScriptUtils.Trim(const Str: String): String;
begin
  try
    Result := SysUtils.Trim(Str);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11750
//* Removes blank and control characters (such as line feed) from the start of a string.
function TKMScriptUtils.TrimLeft(const Str: String): String;
begin
  try
    Result := SysUtils.TrimLeft(Str);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11750
//* Removes blank and control characters (such as line feed) from the end of a string.
function TKMScriptUtils.TrimRight(const Str: String): String;
begin
  try
    Result := SysUtils.TrimRight(Str);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


//* Version: 11750
//* Changes lower case characters in a string Str to upper case
function TKMScriptUtils.UpperCase(const Str: String): String;
begin
  try
    Result := SysUtils.AnsiUpperCase(Str);
  except
    gScriptEvents.ExceptionOutsideScript := True;
    raise;
  end;
end;


end.
