unit KM_ResTexts;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF FPC} lconvencoding, LazUTF8, {$ENDIF}
  Classes, SysUtils, StrUtils, KromUtils,
  KM_CommonClasses, KM_FileIO, KM_ResLocales;


const
  // Take text IDs from this include file that is managed by the Translation Manager
  // NAME__## means that this const defines first element of some range that is ## long
  {$I KM_TextIDs.inc}

  // Supposed for places where some text must be placed
  // That string was used in all Synetic games for missing texts
  NO_TEXT = '<<<LEER>>>';

  MISSION_NAME_LIBX_ID = 200; //Reserved Libx ID for Mission name in Campaigns
  LIBX_NO_ID = -1;

type
  TKMTextLibraryCommon = class
  private
    procedure LoadLIBXFile(const FilePath: string; var aArray: TUnicodeStringArray; aFullScan: Boolean = False);
  end;


  TKMTextLibrarySingle = class(TKMTextLibraryCommon)
  private
    fTexts: TUnicodeStringArray;
    function GetTexts(aIndex: Word): UnicodeString;
  public
    procedure LoadLocale(const aPathTemplate: string); // Initial locale for UI strings
    property Texts[aIndex: Word]: UnicodeString read GetTexts; default;
    function IsIndexValid(aIndex: Word): Boolean;
  end;


  TKMTextLibraryMulti = class(TKMTextLibraryCommon)
  private const
    HANDS_NAMES_OFFSET = 100;
  private
    fPref: array [0..2] of Integer;

    fTexts: array of TUnicodeStringArray;
    fForceDefaultLocale: Boolean; //Force to use default Locale (Eng)
    function GetTexts(aIndex: Word): UnicodeString;
    {$IFDEF WDC}
    function GetTextsArgs(aIndex: Word; aArgs: array of const): string;
    {$ENDIF}
    function GetDefaultTexts(aIndex: Word): UnicodeString;
    procedure InitLocaleIds;
    function DoParseTextMarkup(const aText: UnicodeString; aTagSym: Char): UnicodeString;
  public
    constructor Create;
    procedure LoadLocale(const aPathTemplate: string; aFullScan: Boolean = False); // All locales for Mission strings
    procedure Clear;
    function ParseTextMarkup(const aText: UnicodeString): UnicodeString; overload;
    function ParseTextMarkup(const aText: UnicodeString; aParams: array of const): UnicodeString; overload;
    function HasText(aIndex: Word): Boolean;
    property Texts[aIndex: Word]: UnicodeString read GetTexts; default;

    function HasHandNameText(aIndex: Word): Boolean;
    function GetHandNameText(aIndex: Word): UnicodeString;

    // Unfortunately Lazarus could not compile constructions like:
    // - 2 properties with the same name
    // - 2 default properties
    // - property with argument type of 'array of const'
    {$IFDEF WDC}
    property Texts[aIndex: Word; aArgs: array of const]: string read GetTextsArgs; default;
    {$ENDIF}
    property DefaultTexts[aIndex: Word]: UnicodeString read GetDefaultTexts;
    property ForceDefaultLocale: Boolean read fForceDefaultLocale write fForceDefaultLocale;
    procedure Save(aStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
  end;


var
  // All games texts accessible from everywhere
  gResTexts: TKMTextLibraryMulti;

implementation
uses
  Math;

{ TKMTextLibraryCommon }
// LIBX files consist of lines. Each line has an index and a text. Lines without index are skipped
procedure TKMTextLibraryCommon.LoadLIBXFile(const FilePath: string; var aArray: TUnicodeStringArray; aFullScan: Boolean = False);

  function TextToArray(const aText: UnicodeString): TUnicodeStringArray;
  var
    P, start: PWideChar;
    S: UnicodeString;
  begin
    SetLength(Result, 0);
    P := Pointer(aText);
    if P = nil then Exit;

    // This is a lot faster than using StrPos/AnsiStrPos when
    // LineBreak is the default (#13#10)
    while P^ <> #0 do
    begin
      start := P;
      while not KromUtils.CharInSet(P^, [#0, #10, #13]) do Inc(P);
      SetString(S, start, P - start);

      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := S;

      if P^ = #13 then Inc(P);
      if P^ = #10 then Inc(P);
    end;
  end;
var
  tmp: TUnicodeStringArray;
  langCode: AnsiString;
  libTxt: UnicodeString;
  I: Integer;
  s: UnicodeString;
  firstDelimiter: Integer;
  id, topId, lineId: Integer;
  {$IFDEF FPC} tmpA: AnsiString; {$ENDIF}
begin
  if not FileExists(FilePath) then Exit;

  // Load ANSI file with codepage we say into unicode string
  langCode := AnsiString(Copy(FilePath, Length(FilePath) - 7, 3));
  libTxt := ReadTextU(FilePath, gResLocales.LocaleByCode(langCode).FontCodepage);
  tmp := TextToArray(libTxt);

  topId := -1;

  for I := High(tmp) downto 0 do
  begin
    firstDelimiter := Pos(':', tmp[I]);
    if firstDelimiter = 0 then Continue;

    if TryStrToInt(LeftStr(tmp[I], firstDelimiter - 1), lineId) then
    begin
      if not aFullScan then
      begin
        topId := lineId;
        Break;
      end;
      topId := Max(lineId, topId);
    end;
  end;

  // No strings were found
  if topId = -1 then Exit;

  Assert(topId <= 2048, 'Don''t allow too many strings for no reason');

  // Don't shrink the array, we might be overloading base locale with a partial translation
  if Length(aArray) < topId + 1 then
    SetLength(aArray, topId + 1);

  for I := 0 to High(tmp) do
  begin
    s := tmp[I];

    // Get string index and skip erroneous lines
    firstDelimiter := Pos(':', s);
    if firstDelimiter = 0 then Continue;
    if not TryStrToInt(TrimLeft(LeftStr(s, firstDelimiter - 1)), id) then Continue;

    s := RightStr(s, Length(s) - firstDelimiter);
    // Required characters that can't be stored in plain text
    //todo: Remove them in favor of | for eol (and update libx files)
    {$IFDEF WDC}
    s := StringReplace(s, '\n', EolW, [rfReplaceAll, rfIgnoreCase]); // EOL
    s := StringReplace(s, '\\', '\', [rfReplaceAll, rfIgnoreCase]); // Slash
    {$ENDIF}
    {$IFDEF FPC}
    // In FPC StringReplace only works for UTF8/Ansi strings
    tmpA := UTF16toUTF8(s);
    tmpA := StringReplace(tmpA, '\n', EolW, [rfReplaceAll, rfIgnoreCase]); // EOL
    tmpA := StringReplace(tmpA, '\\', '\', [rfReplaceAll, rfIgnoreCase]); // Slash
    s := UTF8toUTF16(tmpA);
    {$ENDIF}
    aArray[id] := s;
  end;
end;


function TKMTextLibrarySingle.GetTexts(aIndex: Word): UnicodeString;
begin
  if aIndex < Length(fTexts) then
    Result := fTexts[aIndex]
  else
    Result := '~~~String ' + IntToStr(aIndex) + ' out of range!~~~';
end;


function TKMTextLibrarySingle.IsIndexValid(aIndex: Word): Boolean;
begin
  Result := aIndex < Length(fTexts);
end;


// Text file template, e.g.: ExeDir\text.%s.libx
// We need locale separate to assemble Fallback and Default locales paths
procedure TKMTextLibrarySingle.LoadLocale(const aPathTemplate: string);
begin
  // We load the English LIBX by default, then overwrite it with the selected language
  // (this way missing strings are in English)
  LoadLIBXFile(Format(aPathTemplate, [gResLocales.DefaultLocale]), fTexts, True);

  if gResLocales.FallbackLocale <> '' then
    LoadLIBXFile(Format(aPathTemplate, [gResLocales.FallbackLocale]), fTexts, True);

  LoadLIBXFile(Format(aPathTemplate, [gResLocales.UserLocale]), fTexts, True);
end;


{ TKMTextLibraryMulti }
constructor TKMTextLibraryMulti.Create;
begin
  inherited Create;

  InitLocaleIds;
  fForceDefaultLocale := False;
end;


procedure TKMTextLibraryMulti.InitLocaleIds;
begin
  // Using indexes is faster than always looking them up for every string requested
  fPref[0] := gResLocales.IndexByCode(gResLocales.UserLocale);
  fPref[1] := gResLocales.IndexByCode(gResLocales.FallbackLocale);
  fPref[2] := gResLocales.IndexByCode(gResLocales.DefaultLocale);
end;


// Check if requested string is empty
function TKMTextLibraryMulti.HasText(aIndex: Word): Boolean;
begin
  Result := ((fPref[0] <> -1) and (aIndex < Length(fTexts[fPref[0]])) and (fTexts[fPref[0], aIndex] <> ''))
         or ((fPref[1] <> -1) and (aIndex < Length(fTexts[fPref[1]])) and (fTexts[fPref[1], aIndex] <> ''))
         or ((fPref[2] <> -1) and (aIndex < Length(fTexts[fPref[2]])) and (fTexts[fPref[2], aIndex] <> ''));
end;


function TKMTextLibraryMulti.HasHandNameText(aIndex: Word): Boolean;
begin
  Result := HasText(HANDS_NAMES_OFFSET + aIndex);
end;


function TKMTextLibraryMulti.GetHandNameText(aIndex: Word): UnicodeString;
begin
  Result := GetTexts(HANDS_NAMES_OFFSET + aIndex);
end;


// Order of preference: Locale > Fallback > Default(Eng)
// Some locales may have no strings at all, just skip them
function TKMTextLibraryMulti.GetTexts(aIndex: Word): UnicodeString;
var
  found: Boolean;
begin
  found := False;

  if (fPref[0] <> -1) and (aIndex < Length(fTexts[fPref[0]])) and (fTexts[fPref[0], aIndex] <> '') then
  begin
    Result := fTexts[fPref[0], aIndex];
    found := True;
  end
  else
  if (fPref[1] <> -1) and (aIndex < Length(fTexts[fPref[1]])) and (fTexts[fPref[1], aIndex] <> '') then
  begin
    Result := fTexts[fPref[1], aIndex];
    found := True;
  end;

  if (not found or fForceDefaultLocale) then
  begin
    if (fPref[2] <> -1) and (aIndex < Length(fTexts[fPref[2]])) and (fTexts[fPref[2], aIndex] <> '') then
    begin
      Result := fTexts[fPref[2], aIndex];
      found := True;
    end;
  end;
  if not found then
    Result := '~~~String ' + IntToStr(aIndex) + ' out of range!~~~';
end;


{$IFDEF WDC}
function TKMTextLibraryMulti.GetTextsArgs(aIndex: Word; aArgs: array of const): string;
begin
  Result := Format(GetTexts(aIndex), aArgs);
end;
{$ENDIF}


// Returns in text default locale
function TKMTextLibraryMulti.GetDefaultTexts(aIndex: Word): UnicodeString;
begin
  if (fPref[2] <> -1) and (aIndex < Length(fTexts[fPref[2]])) and (fTexts[fPref[2], aIndex] <> '') then
    Result := fTexts[fPref[2], aIndex]
  else
    Result := '~~~String ' + IntToStr(aIndex) + ' out of range!~~~';
end;


procedure TKMTextLibraryMulti.Clear;
begin
  SetLength(fTexts, 0);
end;


// Path template with %s
procedure TKMTextLibraryMulti.LoadLocale(const aPathTemplate: string; aFullScan: Boolean = False);
var
  I: Integer;
begin
  SetLength(fTexts, gResLocales.Count);

  for I := 0 to gResLocales.Count - 1 do
    LoadLIBXFile(Format(aPathTemplate, [gResLocales[I].Code]), fTexts[I], aFullScan);
end;


// Dynamic Scripts should not have access to the actual strings (script variables should be identical for all MP players)
// Take the string and replace every occurence of <$tag> with corresponding text from LibX
// - aTagSym says which tags should be replaced ($ for missions, % for game texts)
function TKMTextLibraryMulti.DoParseTextMarkup(const aText: UnicodeString; aTagSym: Char): UnicodeString;
var
  I, ID, last: Integer;
begin
  Assert((aTagSym = '$') or (aTagSym = '%'));

  Result := '';
  I := 1;
  while I <= Length(aText) do
  begin
    if (I + 3 <= Length(aText)) and (aText[I] = '<') and (aText[I+1] = aTagSym) then
    begin
      last := PosEx('>', aText, I);
      ID := StrToIntDef(Copy(aText, I+2, last-(I+2)), -1);
      if ID >= 0 then
      begin
        Result := Result + Texts[ID];
        I := last + 1;
        Continue;
      end;
    end;
    Result := Result + aText[I];
    Inc(I);
  end;
end;


function TKMTextLibraryMulti.ParseTextMarkup(const aText: UnicodeString): UnicodeString;
begin
  Assert(Self <> gResTexts, 'Only missions so far can do text parsing');

  Result := DoParseTextMarkup(aText, '$');
  Result := gResTexts.DoParseTextMarkup(Result, '%');
end;


function TKMTextLibraryMulti.ParseTextMarkup(const aText: UnicodeString; aParams: array of const): UnicodeString;
begin
  Result := ParseTextMarkup(Format(ParseTextMarkup(aText), aParams));
end;


procedure TKMTextLibraryMulti.Save(aStream: TKMemoryStream);

  function LocalesWithText: Integer;
  var
    I: Integer;
  begin
    Result := 0;
    for I := 0 to gResLocales.Count - 1 do
      if Length(fTexts[I]) > 0 then
        Inc(Result);
  end;

var
  I, K: Integer;
  textCount: Integer;
begin
  aStream.PlaceMarker('TextLibraryMulti');
  // Only save locales containing text (otherwise locale list must be synced in MP)
  aStream.Write(LocalesWithText);
  for I := 0 to gResLocales.Count - 1 do
    if Length(fTexts[I]) > 0 then
    begin
      aStream.WriteA(gResLocales[I].Code);

      textCount := Length(fTexts[I]);

      aStream.Write(textCount);
      for K := 0 to textCount - 1 do
        aStream.WriteW(fTexts[I,K]);
    end;
end;


procedure TKMTextLibraryMulti.Load(LoadStream: TKMemoryStream);
var
  I, K: Integer;
  locCount, textCount: Integer;
  curLoc: AnsiString;
  ID: Integer;
  tmp: UnicodeString;
begin
  // Try to match savegame locales with players locales,
  // because some players might have non-native locales missing
  // We might add locale selection to setup.exe
  LoadStream.CheckMarker('TextLibraryMulti');
  SetLength(fTexts, gResLocales.Count);

  LoadStream.Read(locCount);
  for I := 0 to locCount - 1 do
  begin
    LoadStream.ReadA(curLoc);
    ID := gResLocales.IndexByCode(curLoc);

    LoadStream.Read(textCount);

    if ID <> -1 then
    begin
      SetLength(fTexts[ID], textCount);
      for K := 0 to textCount - 1 do
        LoadStream.ReadW(fTexts[ID,K]);
    end
    else
    begin
      for K := 0 to textCount - 1 do
        LoadStream.ReadW(tmp);
    end;
  end;

  InitLocaleIds;
end;


end.
