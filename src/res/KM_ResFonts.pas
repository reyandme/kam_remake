unit KM_ResFonts;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, Graphics,
  KM_CommonTypes, KM_RenderTypes,
  KM_Points, KM_ResPalettes;


const
  FONT_TAB_WIDTH = 30;

type
  //* Font type
  TKMFont = (
    fntAntiqua,
    fntGame,
    fntGrey,
    fntMetal,
    fntMini,
    fntOutline,
    fntArial, // Arial for MP chat
    fntMonospaced // Debug overlay font (Consolas 8. Set WordSpacing to any Char.Width)
  );

const
  FontTypeName: array [TKMFont] of string = (
    // Used in:
    //  - data\gfx\fonts\filenames
    //  - utils\FontX Generator\fonts.xml

    'antiqua',
    'game',
    'grey',
    'metal',
    'mini',
    'outline',
    'arial',
    'consolas8'
  );

type
  TKMFontLoadLevel = (fllFull, fllMinimal);
  {
  Removed fonts that were in KaM:
  Adam (unused)
  Briefing (same typeface as Antiqua, just darker)
  Font01 (damaged)
  KMLobby (used for internet lobby in TPR)
  MainA (identical to MainMapGold in all game versions)
  MainA.old (probably never meant to be included in the release anyway)
  MainB (identical to Game)
  MainMapGold (same typeface as Metal, just with a goldish tint)
  Minimum (same as mini but with less characters)
  System (unused)
  Won (same typeface as Metal, just with a blueish tint)
  }

  TKMFontInfo = record
  public
    Pal: TKMPal; //Palette fnt needs
    TexMode: TKMTexFormat; //Format font texture needs to be in
  end;

  TKMLetter = packed record
  public
    Width, Height: Word;
    YOffset: SmallInt;
    AtlasId: Word; //Was Unknown field, we use it for multi-atlas fonts to mark the letters location
    u1, v1, u2, v2: Single; //Location within texture atlas
  end;

  TKMFontSpec = class
  const
    DEFAULT_EXT = 'fntx';
    FNTX_HEAD: AnsiString = 'FNTX';
    FONTS_FOLDER = 'data' + PathDelim + 'gfx' + PathDelim + 'fonts' + PathDelim;
  private
    fFont: TKMFont;
    function GetTexID(aIndex: Integer): Cardinal;
    function GetLineHeight: SmallInt;
  protected
    fTexSizeX, fTexSizeY: Word; //All atlases have same dimensions
    //Character atlases
    fAtlasCount: Byte;
    fAtlases: array of record
      TexID: Cardinal;
      TexData: TKMCardinalArray;
    end;
    fCharCount: Word;
    fBaseHeight, fWordSpacing, fCharSpacing, fUnknown: SmallInt;
    fLineSpacing: Byte; //Not in KaM files, we use custom value that fits well
    fCodepage: Word;
    fIsUnicode: Boolean;

    fMaxWidth: Integer;
    fRawData: array [0..High(Word)] of array of Byte; //Raw data for ANSI fonts
  public
    Used: array [0..High(Word)] of Byte;
    Letters: array [0..High(Word)] of TKMLetter;

    constructor Create(aFont: TKMFont);

    procedure LoadFont(const aFileName: string; aPalette: TKMPaletteSpec);
    procedure LoadFontX(const aFileName: string; aLoadLevel: TKMFontLoadLevel = fllFull);
    procedure GenerateTextures(aTexMode: TKMTexFormat);
    procedure Compact;
    procedure ExportAtlasBmp(aBitmap: TBitmap; aIndex: Integer; aShowCells: Boolean); overload;
    procedure ExportAtlasBmp(const aPath: string; aIndex: Integer); overload;
    procedure ExportAtlasPng(const aFilename: string; aIndex: Integer); overload;

    function GetLetter(aChar: WideChar): TKMLetter;
    property AtlasCount: Byte read fAtlasCount;
    property TexID[aIndex: Integer]: Cardinal read GetTexID;

    property CharCount: Word read fCharCount;
    property CharSpacing: SmallInt read fCharSpacing;
    property LineSpacing: Byte read fLineSpacing;
    property LineHeight: SmallInt read GetLineHeight;
    property BaseHeight: SmallInt read fBaseHeight;
    property WordSpacing: SmallInt read fWordSpacing;

    function GetCharWidth(aChar: WideChar; aConsiderEolSymbol: Boolean = False): Integer;
    function WordWrap(aText: UnicodeString; aMaxPxWidth: Integer; aForced: Boolean; aIndentAfterNL: Boolean;
      aTabWidth: Integer = FONT_TAB_WIDTH): UnicodeString;
    function CharsThatFit(const aText: UnicodeString; aMaxPxWidth: Integer; aRound: Boolean = False;
      aConsiderEolSymbol: Boolean = False; aTabWidth: Integer = FONT_TAB_WIDTH): Integer;
    function GetTextSize(const aText: UnicodeString; var aLineCount: Integer; aCountMarkup: Boolean = False;
      aConsiderEolSymbol: Boolean = False; aTabWidth: Integer = FONT_TAB_WIDTH): TKMPoint; overload;
    function GetTextSize(const aText: UnicodeString; aCountMarkup: Boolean = False; aConsiderEolSymbol: Boolean = False;
      aTabWidth: Integer = FONT_TAB_WIDTH): TKMPoint; overload;
    function GetMaxPrintWidthOfStrings(aStrings: array of string): Integer;
  end;


  //Collection of fonts
  TKMResFonts = class
  private
    fLoadLevel: TKMFontLoadLevel;
    fFontData: array [TKMFont] of TKMFontSpec;
    function GetFontData(aIndex: TKMFont): TKMFontSpec;
  public
    constructor Create;
    destructor Destroy; override;

    property FontData[aIndex: TKMFont]: TKMFontSpec read GetFontData; default;
    property LoadLevel: TKMFontLoadLevel read fLoadLevel;
    class function GuessPalette(const aFileName: string): TKMPal;

    procedure LoadFonts(aLoadLevel: TKMFontLoadLevel = fllFull);
    procedure ExportFonts;
  end;


const
  PLACEHOLDER_CHAR = 0; // Box, used for characters missing from font

  FONT_INFO: array [TKMFont] of TKMFontInfo = (
    (Pal: pal0;  TexMode: tfRGB5A1),
    (Pal: palbw; TexMode: tfAlpha8),
    (Pal: pal0;  TexMode: tfRGB5A1),
    (Pal: pal0;  TexMode: tfRGB5A1),
    (Pal: palbw; TexMode: tfAlpha8),
    (Pal: pal0;  TexMode: tfRGB5A1),
    (Pal: pal0;  TexMode: tfRGBA8 ),
    (Pal: pal0;  TexMode: tfRGBA8 )
  );


function NameToFont(const aName: string): TKMFont;


implementation
uses
  Classes, Math, StrUtils,
  {$IFDEF FPC} zstream, {$ENDIF}
  {$IFDEF WDC} ZLib, {$ENDIF}
  KM_Defaults, KM_IoPNG,
  {$IFNDEF NO_OGL}
  KM_Render,
  {$ENDIF}
  KM_CommonUtils, KM_Log;


function NameToFont(const aName: string): TKMFont;
var
  I: TKMFont;
begin
  Result := fntAntiqua;
  for I := Low(TKMFont) to High(TKMFont) do
  if FontTypeName[I] = aName then
    Exit(I);
end;


{ TKMFontSpec }
constructor TKMFontSpec.Create(aFont: TKMFont);
begin
  inherited Create;

  fFont := aFont;
end;


procedure TKMFontSpec.LoadFont(const aFileName: string; aPalette: TKMPaletteSpec);
const
  FONT_TEX_SIZE = 256; // Static texture size, all KaM fonts fit within 256^2 space
  FONT_INTERLINE = 5; // Spacing between lines of text
  PAD = 1;
var
  S: TMemoryStream;
  fileName: string;
  I, K, M, L: Integer;
  maxHeight: Integer;
  pX, pY: Integer;
begin
  if not FileExists(aFileName) then
    Exit;

  maxHeight := 0;
  S := TMemoryStream.Create;
  S.LoadFromFile(aFileName);

  //Fnt allows to store 256 or 65000 characters, but there's no flag inside, we can test only filesize
  fCharCount := IfThen(S.Size <= 65000, 256, 65000);

  //Try to get the codepage
  fileName := ExtractFileName(aFileName);
  I := Pos('.', fileName);
  K := PosEx('.', fileName, I+1);

  fCodepage := StrToIntDef(Copy(fileName, I+1, K-I-1), 0);
  fIsUnicode := S.Size > 65000;

  S.Read(fBaseHeight, 2);
  S.Read(fWordSpacing, 2);
  S.Read(fCharSpacing, 2);
  S.Read(fUnknown, 2); //Unknown field
  fLineSpacing := FONT_INTERLINE;

  S.Read(Used[0], fCharCount);

  //Read font data
  for I := 0 to fCharCount - 1 do
  if Used[I] <> 0 then
  begin
    S.Read(Letters[I].Width, 2);
    S.Read(Letters[I].Height, 2);
    S.Read(Letters[I].AtlasId, 2); //was Unknown field
    S.Seek(2, soFromCurrent); //Unknown field
    S.Read(Letters[I].YOffset, 2);
    S.Seek(2, soFromCurrent); //Unknown field

    maxHeight := Math.max(maxHeight, Letters[I].Height);

    if Letters[I].Width * Letters[I].Height = 0 then
      raise Exception.Create('Font data Width * Height = 0'); //Font01.fnt seems to be damaged..

    SetLength(fRawData[I], Letters[I].Width * Letters[I].Height);
    S.Read(fRawData[I,0], Letters[I].Width * Letters[I].Height);
  end;
  S.Free;

  //Compile texture
  pX := PAD;
  pY := PAD;
  fTexSizeX := IfThen(fIsUnicode, FONT_TEX_SIZE * 4, FONT_TEX_SIZE); //256 / 1024
  fTexSizeY := IfThen(fIsUnicode, FONT_TEX_SIZE * 2, FONT_TEX_SIZE); //256 / 512
  fAtlasCount := 1;
  SetLength(fAtlases, 0);
  SetLength(fAtlases, fAtlasCount);
  SetLength(fAtlases[fAtlasCount - 1].TexData, fTexSizeX * fTexSizeY);

  for I := 0 to fCharCount - 1 do
  if Used[I] <> 0 then
  begin
    //Switch to new line
    if pX + Letters[I].Width + PAD > fTexSizeX then
    begin
      pX := PAD;
      Inc(pY, maxHeight + PAD);
    end;

    //Fill in colors
    for L := 0 to Letters[I].Height - 1 do
    for M := 0 to Letters[I].Width - 1 do
      fAtlases[fAtlasCount - 1].TexData[(pY + L) * fTexSizeX + pX + M] :=
        aPalette.Color32(fRawData[I, L * Letters[I].Width + M]);

    Letters[I].u1 := pX / fTexSizeX;
    Letters[I].v1 := pY / fTexSizeY;
    Letters[I].u2 := (pX + Letters[I].Width) / fTexSizeX;
    Letters[I].v2 := (pY + Letters[I].Height) / fTexSizeY;

    Inc(pX, Letters[I].Width + PAD);
  end;
end;


procedure TKMFontSpec.LoadFontX(const aFileName: string; aLoadLevel: TKMFontLoadLevel = fllFull);
var
  inputStream: TFileStream;
  decompressionStream: TDecompressionStream;
  head: AnsiString;
  I: Integer;
begin
  if not FileExists(aFileName) then Exit;

  inputStream := TFileStream.Create(aFileName, fmOpenRead or fmShareDenyNone);
  decompressionStream := TDecompressionStream.Create(inputStream);
  try
    SetLength(head, 4);
    decompressionStream.Read(head[1], 4);

    Assert(head = FNTX_HEAD);

    fCodepage := 0;
    fIsUnicode := True;
    fCharCount := 65535;

    decompressionStream.Read(fBaseHeight, 2);
    decompressionStream.Read(fWordSpacing, 2);
    decompressionStream.Read(fCharSpacing, 2);
    decompressionStream.Read(fLineSpacing, 1);

    decompressionStream.Read(Used[0], Length(Used) * SizeOf(Used[0]));
    for I := 0 to High(Word) do
    if Used[I] <> 0 then
      decompressionStream.Read(Letters[I], SizeOf(TKMLetter));

    decompressionStream.Read(fAtlasCount, 1);
    decompressionStream.Read(fTexSizeX, 2);
    decompressionStream.Read(fTexSizeY, 2);

    if aLoadLevel = fllMinimal then
    begin
      fAtlasCount := 1; //Only load the first atlas
      for I := 0 to High(Word) do
        Used[I] := Byte(Letters[I].AtlasId = 0); //Only allow letters on first atlas
    end;

    SetLength(fAtlases, fAtlasCount);
    for I := 0 to fAtlasCount - 1 do
    begin
      SetLength(fAtlases[I].TexData, fTexSizeX * fTexSizeY);
      decompressionStream.Read(fAtlases[I].TexData[0], fTexSizeX * fTexSizeY * 4);
    end;
  finally
    decompressionStream.Free;
    inputStream.Free;
  end;
end;


// After font has been loaded and texture generated we can flush temp data
procedure TKMFontSpec.Compact;
var
  I: Integer;
begin
  //Discard texture data to save mem
  for I := 0 to fAtlasCount - 1 do
    SetLength(fAtlases[I].TexData, 0);

  fTexSizeX := 0;
  fTexSizeY := 0;
end;


// Generate color texture from prepared data
procedure TKMFontSpec.GenerateTextures(aTexMode: TKMTexFormat);
{$IFNDEF NO_OGL}
var
  I: Integer;
  textureRAM: Cardinal;
{$ENDIF}
begin
  {$IFNDEF NO_OGL}
  // We can compute RAM usage along the way, it's practically free
  textureRAM := 0;

  for I := 0 to fAtlasCount - 1 do
    if fAtlases[I].TexID = 0 then //Don't load atlases twice if switching from minimal to full
      if Length(fAtlases[I].TexData) <> 0 then
      begin
        fAtlases[I].TexID := TKMRender.GenTexture(fTexSizeX, fTexSizeY, @fAtlases[I].TexData[0], aTexMode, ftNearest, ftNearest);
        Inc(textureRAM, fTexSizeX * fTexSizeY * TEX_FORMAT_SIZE[aTexMode]);
      end
      else
        fAtlases[I].TexID := 0;

  if LOG_FONTS_RAM_USAGE then
    gLog.AddNoTime('Font RAM usage: ' + IntToStr(textureRAM));
  {$ENDIF}
end;


function TKMFontSpec.GetLetter(aChar: WideChar): TKMLetter;
begin
  if Used[Ord(aChar)] <> 0 then
    Result := Letters[Ord(aChar)]
  else
    Result := Letters[PLACEHOLDER_CHAR];
end;


function TKMFontSpec.GetTexID(aIndex: Integer): Cardinal;
begin
  Result := fAtlases[aIndex].TexID;
end;


// Export texture atlas into bitmap (just for looks)
procedure TKMFontSpec.ExportAtlasBmp(aBitmap: TBitmap; aIndex: Integer; aShowCells: Boolean);
const
  BG: Integer = $AF6B6B;
var
  I, K: Integer;
{$IFDEF WDC}
  scLine: Cardinal;
  TD: TKMCardinalArray;
  C: Integer;
  A: Byte;
{$ENDIF}
begin
  Assert(Length(fAtlases[aIndex].TexData) > 0, 'There is no font data in memory');

  aBitmap.PixelFormat := pf32bit;
  aBitmap.Width  := fTexSizeX;
  aBitmap.Height := fTexSizeY;

  {$IFDEF WDC}
  //todo -cComplicated: Add Lazarus analog
  TD := fAtlases[aIndex].TexData;
  for I := 0 to fTexSizeY - 1 do
  begin
    scLine := Cardinal(aBitmap.ScanLine[I]);
    for K := 0 to fTexSizeX - 1 do
    begin
      C := TD[I * fTexSizeX + K] and $FFFFFF;
      A := 255 - (TD[I * fTexSizeX + K] shr 24) and $FF;
      //C + (D - C) * A
      PCardinal(scLine + K * 4)^ := ((C and $FF) + ((BG and $FF - C and $FF) * A) div 255) shl 16 +
                                    ((C shr 8 and $FF) + ((BG shr 8 and $FF - C shr 8 and $FF) * A) div 255) shl 8 +
                                    ((C shr 16 and $FF) + ((BG shr 16 and $FF - C shr 16 and $FF) * A) div 255);
    end;
  end;
  {$ENDIF}

  if aShowCells then
  begin
    aBitmap.Canvas.Brush.Style := bsClear;
    aBitmap.Canvas.Pen.Color := clAqua;
    for I := 0 to High(Word) do
    if (Used[I] <> 0) and (Letters[I].AtlasId = aIndex) then
    begin
      //Draw cell outside letter area
      aBitmap.Canvas.Rectangle(Round(Letters[I].u1 * fTexSizeX)-1,
                               Round(Letters[I].v1 * fTexSizeY)-1,
                               Round(Letters[I].u2 * fTexSizeX)+1,
                               Round(Letters[I].v2 * fTexSizeY)+1);
    end;
  end;
end;


// Export texture atlas into a bitmap file (just for looks)
procedure TKMFontSpec.ExportAtlasBmp(const aPath: string; aIndex: Integer);
var
  exportBmp: TBitmap;
begin
  Assert(Length(fAtlases[aIndex].TexData) > 0, 'There is no font data in memory');

  exportBmp := TBitMap.Create;
  try
    ExportAtlasBmp(exportBmp, aIndex, False);

    ForceDirectories(ExtractFilePath(aPath));
    exportBmp.SaveToFile(aPath);
  finally
    exportBmp.Free;
  end;
end;


procedure TKMFontSpec.ExportAtlasPng(const aFilename: string; aIndex: Integer);
var
  I, K: Integer;
  pngWidth, pngHeight: Word;
  pngData: TKMCardinalArray;
begin
  Assert(Length(fAtlases[aIndex].TexData) > 0, 'There is no font data in memory');

  pngWidth := fTexSizeX;
  pngHeight := fTexSizeY;
  SetLength(pngData, pngWidth * pngHeight);

  for I := 0 to fTexSizeY - 1 do
  for K := 0 to fTexSizeX - 1 do
    pngData[I * fTexSizeX + K] := PCardinal(Cardinal(@fAtlases[aIndex].TexData[0]) + (I * fTexSizeX + K) * 4)^;

  SaveToPng(pngWidth,pngHeight, pngData, aFilename);
end;


{ TKMResFonts }
constructor TKMResFonts.Create;
var
  F: TKMFont;
begin
  inherited;

  for F := Low(TKMFont) to High(TKMFont) do
    fFontData[F] := TKMFontSpec.Create(F);
end;


destructor TKMResFonts.Destroy;
var
  F: TKMFont;
begin
  for F := Low(TKMFont) to High(TKMFont) do
    fFontData[F].Free;

  inherited;
end;


function TKMResFonts.GetFontData(aIndex: TKMFont): TKMFontSpec;
begin
  Result := fFontData[aIndex];
end;


class function TKMResFonts.GuessPalette(const aFileName: string): TKMPal;
var
  fileName: string;
  filePart: string;
  I: Integer;
  F: TKMFont;
begin
  Result := palmap;

  fileName := ExtractFileName(aFileName);
  I := Pos('.', fileName);
  filePart := Copy(fileName, 1, I-1);

  for F := Low(TKMFont) to High(TKMFont) do
    if FontTypeName[F] = filePart then
      Result := FONT_INFO[F].Pal;
end;


procedure TKMResFonts.LoadFonts(aLoadLevel: TKMFontLoadLevel = fllFull);
var
  F: TKMFont;
  fntPath: string;
  startTime, totalTime: Cardinal;
begin
  gLog.AddTime('Load font started');
  fLoadLevel := aLoadLevel;
  startTime := TimeGet;

  for F := Low(TKMFont) to High(TKMFont) do
  begin
    fntPath := ExeDir + TKMFontSpec.FONTS_FOLDER + FontTypeName[F] + '.' + TKMFontSpec.DEFAULT_EXT;
    fFontData[F].LoadFontX(fntPath, aLoadLevel);
    fFontData[F].GenerateTextures(FONT_INFO[F].TexMode);
    fFontData[F].Compact;
  end;

  totalTime := TimeSince(startTime);
  gLog.AddTime('Font load took ' + IntToStr(totalTime) + 'ms');
end;


procedure TKMResFonts.ExportFonts;
var
  F: TKMFont;
  fntPath: string;
  I: Integer;
begin
  // We need to reload fonts to regenerate TexData
  for F := Low(TKMFont) to High(TKMFont) do
  begin
    fntPath := ExeDir + TKMFontSpec.FONTS_FOLDER + FontTypeName[F] + '.' + TKMFontSpec.DEFAULT_EXT;
    fFontData[F].LoadFontX(fntPath);

    for I := 0 to fFontData[F].AtlasCount - 1 do
      fFontData[F].ExportAtlasBmp(ExeDir + 'Export' + PathDelim + 'Fonts' + PathDelim + FontTypeName[F] + IntToStr(I) + '.bmp', I);
    fFontData[F].Compact;
  end;
end;


function TKMFontSpec.GetLineHeight: SmallInt;
begin
  Result := BaseHeight + LineSpacing;
end;


function TKMFontSpec.GetCharWidth(aChar: WideChar; aConsiderEolSymbol: Boolean = False): Integer;
begin
  if (not aConsiderEolSymbol and (aChar = #124)) or (aChar = #9) then
    Result := 0
  else
  if aChar = #32 then
    Result := WordSpacing
  else
    Result := GetLetter(aChar).Width + CharSpacing;

  // CharSpacing could be negative
  Result := Max(0, Result);
end;


function TKMFontSpec.WordWrap(aText: UnicodeString; aMaxPxWidth: Integer; aForced: Boolean; aIndentAfterNL: Boolean;
                              aTabWidth: Integer = FONT_TAB_WIDTH): UnicodeString;
const
  INDENT = '   ';
var
  I, lineWrapPos: Integer;
  lastWrappable: Integer;
  lastWrappableIsSpace: Boolean;
  lastColorMarkup, afterWrapClMarkup: UnicodeString;
  dx, prevX: Integer;
  tmpColor: Integer;
begin
  Assert(aMaxPxWidth > 0);

  if aText = '' then Exit ('');

  dx := 0;
  prevX := 0;
  lastWrappable := -1;
  lastWrappableIsSpace := False;
  lastColorMarkup := '';
  afterWrapClMarkup := '';

  I := 1;
  while I <= Length(aText) do
  begin
    //Chinese/Japanese characters (not punctuation) can always be wrapped before
    //Check this before we update dx since we are allowing wrapping before this char
    if ((Ord(aText[I]) >= 19968) and (Ord(aText[I]) <= 40870))
      or ((Ord(aText[I]) >= $3040) and (Ord(aText[I]) <= $30ff)) then
    begin
      lastWrappable := I;
      afterWrapClMarkup := lastColorMarkup;
      prevX := dx; //dx does not include this char yet, since we are wrapping before it
      lastWrappableIsSpace := False;
    end;

    //Ignore color markups [$FFFFFF][]
    if (aText[I] = '[') and (I+1 <= Length(aText)) and (aText[I+1] = ']') then
    begin
      lastColorMarkup := '';
      Inc(I); //Skip past end of color markup
    end else
      if (aText[I] = '[') and (I+8 <= Length(aText))
        and (aText[I+1] = '$') and (aText[I+8] = ']')
        and TryStrToInt(Copy(aText, I+1, 7), tmpColor) then
      begin
        lastColorMarkup := Copy(aText, I, 9);
        Inc(I,8); //Skip past start of color markup
      end else if (aText[I] = #9) then
        dx := (Floor(dx / aTabWidth) + 1) * aTabWidth
      else
        Inc(dx, GetCharWidth(aText[I]));

    if SysUtils.CharInSet(aText[I], [#9,#32,#124]) then
    begin
      lastWrappable := I;
      afterWrapClMarkup := lastColorMarkup;
      prevX := dx;
      lastWrappableIsSpace := True;
    end;

    //This algorithm is not perfect, somehow line width is not within SizeX, but very rare
    if ((dx > aMaxPxWidth) and (lastWrappable <> -1)) or (aText[I] = #124) then
    begin
      if lastWrappableIsSpace then
        aText[lastWrappable] := #124 //Replace last whitespace with EOL
      else begin
        Inc(lastWrappable);
        Insert(#124, aText, lastWrappable); //Insert EOL after last wrappable char
      end;

      if afterWrapClMarkup <> '' then
      begin
        Insert('[]', aText, lastWrappable);
        Inc(I, 2);
        Inc(lastWrappable, 2);
      end;

      if (aText[I] <> #124) and aIndentAfterNL then
      begin
        Insert(INDENT, aText, lastWrappable+1);
        Inc(I, Length(INDENT));
        Inc(dx, Length(INDENT) * WordSpacing);
      end;

      if afterWrapClMarkup <> '' then
      begin
        Insert(afterWrapClMarkup, aText, lastWrappable+1);
        Inc(I, Length(afterWrapClMarkup));
      end;

      Dec(dx, prevX); //Subtract width since replaced whitespace

      lastWrappable := -1;
    end;
    //Force an EOL part way through a word
    if aForced and (dx > aMaxPxWidth) and (lastWrappable = -1) then
    begin
      Insert(#124, aText, I); //Insert an EOL before this character
      dx := 0;

      if lastColorMarkup <> '' then
      begin
        Insert('[]', aText, I);
        Inc(I, 2);
      end;

      lineWrapPos := I;

      if aIndentAfterNL then
      begin
        Insert(INDENT, aText, I+1);
        Inc(I, Length(INDENT));
        Inc(dx, Length(INDENT) * WordSpacing);
      end;

      if lastColorMarkup <> '' then
      begin
        Insert(lastColorMarkup, aText, lineWrapPos+1);
        Inc(I, Length(lastColorMarkup));
      end;

      lastWrappable := -1;
    end;
    Inc(I);
  end;
  Result := aText;
end;


function TKMFontSpec.CharsThatFit(const aText: UnicodeString; aMaxPxWidth: Integer; aRound: Boolean = False;
                                  aConsiderEolSymbol: Boolean = False; aTabWidth: Integer = FONT_TAB_WIDTH): Integer;
var
  I, dx, prevX, lastCharW: Integer;
begin
  dx := 0;
  Result := Length(aText);

  for I := 1 to Length(aText) do
  begin
    lastCharW := GetCharWidth(aText[I], aConsiderEolSymbol);
    prevX := dx;
    if aText[I] = #9 then
      dx := (Floor(dx / aTabWidth) + 1) * aTabWidth
    else
      Inc(dx, lastCharW);

    if (dx > aMaxPxWidth) then
    begin
      // If we want to get approximate result, then check if total width is closer to prev width or to current
      if aRound and (dx - aMaxPxWidth < aMaxPxWidth - prevX) then
        Result := I
      else
        Result := I - 1; //Previous character fits, this one does not
      Exit;
    end;
  end;
end;


function TKMFontSpec.GetTextSize(const aText: UnicodeString; aCountMarkup: Boolean = False; aConsiderEolSymbol: Boolean = False;
                                 aTabWidth: Integer = FONT_TAB_WIDTH): TKMPoint;
var
  lineCount: Integer;
begin
  Result := GetTextSize(aText, lineCount, aCountMarkup, aConsiderEolSymbol, aTabWidth);
end;


function TKMFontSpec.GetTextSize(const aText: UnicodeString; var aLineCount: Integer; aCountMarkup: Boolean = False;
                                 aConsiderEolSymbol: Boolean = False; aTabWidth: Integer = FONT_TAB_WIDTH): TKMPoint;
var
  I: Integer;
  lineWidthInc, tmpColor: Integer;
  lineWidth: array of Integer; // Some fonts may have negative CharSpacing
begin
  Result.X := 0;
  Result.Y := 0;

  if aText = '' then Exit;

  aLineCount := 1;
  if not aConsiderEolSymbol then
    for I := 1 to Length(aText) do
      if aText[I] = #124 then Inc(aLineCount);

  SetLength(lineWidth, aLineCount+2); //1..n+1 (for last line)

  aLineCount := 1;
  I := 1;
  while I <= Length(aText) do
  begin
    lineWidthInc := 0;
    if aCountMarkup then
    begin
      //Count all characters including markup
      if aText[I] = #9 then // Tab char
        lineWidthInc := (Floor(lineWidth[aLineCount] / aTabWidth) + 1) * aTabWidth - lineWidth[aLineCount]
      else
        lineWidthInc := GetCharWidth(aText[I], aConsiderEolSymbol);
      Inc(lineWidth[aLineCount], lineWidthInc);
    end else
      //Ignore color markups [$FFFFFF][]
      if (aText[I]='[') and (I+1 <= Length(aText)) and (aText[I+1]=']') then
        Inc(I) //Skip past this markup
      else
        if (aText[I]='[') and (I+8 <= Length(aText))
          and (aText[I+1] = '$') and (aText[I+8]=']')
          and TryStrToInt(Copy(aText, I+1, 7), tmpColor) then
          Inc(I,8) //Skip past this markup
        else begin
          //Not markup so count width normally
          if aText[I] = #9 then // Tab char
            lineWidthInc := (Floor(lineWidth[aLineCount] / aTabWidth) + 1) * aTabWidth - lineWidth[aLineCount]
          else
            lineWidthInc := GetCharWidth(aText[I], aConsiderEolSymbol);
          Inc(lineWidth[aLineCount], lineWidthInc);
        end;

    if (not aConsiderEolSymbol and (aText[I] = #124)) or (I = Length(aText)) then
    begin // If EOL or aText end
      if aText[I] <> #9 then       // for Tab reduce line width for CharSpacing and also for TAB 'jump'
        lineWidthInc := 0;
      lineWidth[aLineCount] := Math.Max(0, lineWidth[aLineCount] - CharSpacing - lineWidthInc);
      // Remove last interletter space and negate double EOLs
      Inc(aLineCount);
    end;
    Inc(I);
  end;

  Dec(aLineCount);
  Result.Y := LineHeight * aLineCount;
  for I := 1 to aLineCount do
    Result.X := Math.Max(Result.X, lineWidth[I]);
end;


// Return maximum of the width of specified strings when printed on screen with specified font.
function TKMFontSpec.GetMaxPrintWidthOfStrings(aStrings: array of string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(aStrings) to High(aStrings) do
    Result := Max(Result, GetTextSize(aStrings[I]).X);
end;


end.
