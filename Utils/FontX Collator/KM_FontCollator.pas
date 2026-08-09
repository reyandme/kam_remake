unit KM_FontCollator;
{$I ..\..\KaM_Remake.inc}
interface
uses
  {$IFDEF WDC} Windows, {$ENDIF} //Declared first to get TBitmap overriden with VCL version
  {$IFDEF FPC} lconvencoding, {$ENDIF}
  Classes, StrUtils, SysUtils,
  KM_CommonTypes, KM_Defaults, KM_FileIO,
  KM_ResFontsEdit, KM_ResPalettes;


type
  TKMFontCollator = class
  private
    fFontDir: string;
    fFonts: TStringList;
  public
    constructor Create;
    destructor Destroy; override;

    property Fonts: TStringList read fFonts;
    procedure Collate(aIndex: Integer; aX, aY, aPad: Word; aFiles: TKMStringArray; var aFont: TKMFontSpecEdit);
    function FontCodepages(aIndex: Integer): string;
    procedure ListFonts(const aPath: string);
  end;


implementation
uses
  KM_ResLocales, KM_ResFonts;


{ TKMFontCollator }
constructor TKMFontCollator.Create;
begin
  inherited;

  fFonts := TStringList.Create;

  gResLocales := TKMResLocales.Create(ExeDir + '..\..\data\locales.txt', DEFAULT_LOCALE);
end;


destructor TKMFontCollator.Destroy;
begin
  gResLocales.Free;
  fFonts.Free;

  inherited;
end;


procedure TKMFontCollator.Collate(aIndex: Integer; aX, aY, aPad: Word; aFiles: TKMStringArray; var aFont: TKMFontSpecEdit);
var
  I: Integer;
  srcFonts: array of TKMFontSpecEdit;
  pals: TKMResPalettes;
  fntPal: TKMPal;
  srcFontFile: string;
begin
  SetLength(srcFonts, Length(aFiles));

  for I := Low(aFiles) to High(aFiles) do
  begin
    srcFonts[I] := TKMFontSpecEdit.Create(fntArial); //fntArial, why not, it looks like we dont care
    srcFontFile := ExeDir + '..\..\' + TKMFontSpec.FONTS_FOLDER + aFiles[I];

    //Guess font palette from filename
    pals := TKMResPalettes.Create;
    pals.LoadPalettes(ExeDir + '..\..\data\gfx\');

    fntPal := TKMResFonts.GuessPalette(srcFontFile);

    if srcFontFile[Length(srcFontFile)] = 'x' then
      srcFonts[I].LoadFontX(srcFontFile)
    else
      srcFonts[I].LoadFont(srcFontFile, pals[fntPal]);
  end;

  aFont := TKMFontSpecEdit.Create(fntArial); //fntArial, why not, it looks like we dont care
  aFont.TexPadding := aPad;
  aFont.TexSizeX := aX;
  aFont.TexSizeY := aY;
  aFont.CollateFonts(srcFonts);

  for I := Low(aFiles) to High(aFiles) do
    srcFonts[I].Free;
end;


function TKMFontCollator.FontCodepages(aIndex: Integer): string;
var
  searchRec: TSearchRec;
begin
  Result := '';

  if FindFirst(fFontDir + fFonts[aIndex] + '*.fnt?', faAnyFile - faDirectory, searchRec) = 0 then
  try
    repeat
      Result := Result + searchRec.Name + sLineBreak;
    until FindNext(searchRec) <> 0;
  finally
    FindClose(searchRec);
  end;
end;


procedure TKMFontCollator.ListFonts(const aPath: string);
var
  searchRec: TSearchRec;
  I: Integer;
  fntName: string;
begin
  fFonts.Clear;
  fFontDir := '';

  if not DirectoryExists(aPath) then Exit;

  fFontDir := aPath;
  if FindFirst(fFontDir + '*.fnt?', faAnyFile - faDirectory, searchRec) = 0 then
  try
    repeat
      I := Pos('.', searchRec.Name);

      if I = 0 then Continue;

      fntName := Copy(searchRec.Name, 1, I-1);

      if fFonts.IndexOf(fntName) = -1 then
        fFonts.Append(fntName);
    until FindNext(searchRec) <> 0;
  finally
    FindClose(searchRec);
  end;
end;


end.
