unit KM_Resolutions;
{$I KaM_Remake.inc}
interface


type
  TKMScreenRes = record
    Width, Height, RefRate: SmallInt;
  end;

  TKMScreenResIndex = record
    ResId, RefId: Integer; // Allow for -1, when index not found
  end;

  // Store resolution and list of its allowed refresh rates
  TKMScreenResData = record
    Width, Height: Word;
    RefRateCount: Integer;
    RefRate: array of Word;
  end;

  TKMResolutions = class
  private
    fCount: Integer;
    fItems: array of TKMScreenResData;
    fNeedsRestoring: Boolean;

    function GetItem(aIndex: Integer): TKMScreenResData;
    procedure ReadAvailable;
    procedure Sort;
    function SupportedRes(aWidth, aHeight, aRate, aBPP: Word): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Restore; //restores resolution used before program was started

    property Count: Integer read fCount; //Used by UI
    property Items[aIndex: Integer]: TKMScreenResData read GetItem; //Used by UI

    function IsValid(const aResolution: TKMScreenRes): Boolean; //Check, if resolution is correct
    function FindCorrect(const aResolution: TKMScreenRes): TKMScreenRes; //Try to find correct resolution
    function GetResolutionIDs(const aResolution: TKMScreenRes): TKMScreenResIndex;  //prepares IDs for TMainSettings
    procedure SetResolution(const aResolution: TKMScreenRes); //Apply the resolution
  end;


implementation
uses
  Math,
  {$IFDEF MSWindows} Windows, {$ENDIF}
  KM_Defaults;


{ TKMResolutions }
constructor TKMResolutions.Create;
begin
  inherited;

  ReadAvailable;
  Sort;
end;


destructor TKMResolutions.Destroy;
begin
  Restore;

  inherited;
end;


function TKMResolutions.SupportedRes(aWidth, aHeight, aRate, aBPP: Word): Boolean;
begin
  Result := (aBPP = 32) and (aWidth > aHeight)
    and (aWidth >= MIN_RESOLUTION_WIDTH)
    and (aHeight >= MIN_RESOLUTION_HEIGHT)
    and (aRate > 0);
end;


procedure TKMResolutions.ReadAvailable;
{$IFDEF MSWindows}
var
  I, M, N: Integer;
  devMode: TDevMode;
{$ENDIF}
begin
  {$IFDEF MSWindows}
  I := 0;
  fCount := 0;
  while EnumDisplaySettings(nil, I, devMode) do
  with devMode do //todo: Thats bad code, better get rid of this "with"
  begin
    Inc(I);
    // Take only 32bpp modes
    // Exclude rotated modes, as Win reports them too
    if SupportedRes(dmPelsWidth, dmPelsHeight, dmDisplayFrequency, dmBitsPerPel) then
    begin
      // Find next empty place and avoid duplicating
      N := 0;
      while (N < fCount) and (fItems[N].Width <> 0)
            and ((fItems[N].Width <> dmPelsWidth) or (fItems[N].Height <> dmPelsHeight)) do
        Inc(N);

      if N+1 > fCount then
      begin
        SetLength(fItems, N+1);
        FillChar(fItems[N], SizeOf(TKMScreenResData), #0);
        Inc(fCount);
      end;

      if (N < fCount) and (fItems[N].Width = 0) then
      begin
        fItems[N].Width := dmPelsWidth;
        fItems[N].Height := dmPelsHeight;
      end;

      //Find next empty place and avoid duplicating
      M := 0;
      while (N < fCount) and (M < fItems[N].RefRateCount)
            and (fItems[N].RefRate[M] <> 0)
            and (fItems[N].RefRate[M] <> dmDisplayFrequency) do
        Inc(M);

      if M+1 > fItems[N].RefRateCount then
      begin
        SetLength(fItems[N].RefRate, M+1);
        FillChar(fItems[N].RefRate[M], SizeOf(Word), #0);
        Inc(fItems[N].RefRateCount);
      end;

      if (M < fItems[N].RefRateCount) and (N < fCount) and (fItems[N].RefRate[M] = 0) then
        fItems[N].RefRate[M] := dmDisplayFrequency;
    end;
  end;
  {$ENDIF}
end;


procedure TKMResolutions.Sort;
var
  I, J, K: Integer;
  tempScreenResData: TKMScreenResData;
  tempRefRate: Word;
begin
  for I := 0 to fCount - 1 do
  begin
    for J := 0 to fItems[I].RefRateCount - 1 do
    begin
      //firstly, refresh rates for each resolution are being sorted
      K:=J;  //iterator will be modified, but we don't want to lose it
      while ((K>0) and (fItems[I].RefRate[K] < fItems[I].RefRate[K-1]) and
           //excluding zero values from sorting, so they are kept at the end of array
             (fItems[I].RefRate[K] > 0)) do
      begin
        //Exchange places
        tempRefRate := fItems[I].RefRate[K];
        fItems[I].RefRate[K] := fItems[I].RefRate[K-1];
        fItems[I].RefRate[K-1] := tempRefRate;
        dec(K);
      end;
    end;

    if I = 0 then Continue;
    J := I;  //iterator will be modified, but we don't want to lose it
    //moving resolution to its final position
    while ((J>0) and (((fItems[J].Width < fItems[J-1].Width) and
         //excluding zero values from sorting, so they are kept at the end of array
           (fItems[J].Width > 0) and (fItems[J].Height > 0)) or
           ((fItems[J].Width = fItems[J-1].Width) and
           (fItems[J].Height < fItems[J-1].Height)))) do
    begin
      //Exchange places
      tempScreenResData := fItems[J];
      fItems[J] := fItems[J-1];
      fItems[J-1] := tempScreenResData;
      dec(J);
    end;
  end;
end;


function TKMResolutions.GetItem(aIndex: Integer): TKMScreenResData;
begin
  Assert(InRange(aIndex, 0, fCount - 1));
  Result := fItems[aIndex];
end;


procedure TKMResolutions.Restore;
begin
  if not fNeedsRestoring then Exit;
  {$IFDEF MSWindows}
    ChangeDisplaySettings(DEVMODE(nil^), 0);
  {$ENDIF}
  fNeedsRestoring := False;
end;


function TKMResolutions.IsValid(const aResolution: TKMScreenRes): Boolean;
begin
  Result := GetResolutionIDs(aResolution).RefID <> -1;
end;


procedure TKMResolutions.SetResolution(const aResolution: TKMScreenRes);
{$IFDEF MSWindows}
var
  deviceMode: TDeviceMode;
{$ENDIF}
begin
  //Double-check anything we get from outside
  Assert(IsValid(aResolution));

  {$IFDEF MSWindows}
  ZeroMemory(@deviceMode, SizeOf(deviceMode));
  with deviceMode do
  begin
    dmSize := SizeOf(TDeviceMode);
    dmPelsWidth := aResolution.Width;
    dmPelsHeight := aResolution.Height;
    dmBitsPerPel := 32;
    dmDisplayFrequency := aResolution.RefRate;
    dmFields := DM_DISPLAYFREQUENCY or DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
  end;

  ChangeDisplaySettings(deviceMode, CDS_FULLSCREEN);
  {$ENDIF}
  fNeedsRestoring := True; //Resolution was changed so we must restore it when we exit
end;


function TKMResolutions.FindCorrect(const aResolution: TKMScreenRes): TKMScreenRes;
{$IFDEF MSWindows}
var
  devMode: TDevMode;
{$ENDIF}
begin
  //1. Try to reuse current resolution
  {$IFDEF MSWindows}
  EnumDisplaySettings(nil, Cardinal(-1){ENUM_CURRENT_SETTINGS}, devMode);
  with devMode do
  if SupportedRes(dmPelsWidth, dmPelsHeight, dmDisplayFrequency, dmBitsPerPel) then
  begin
    Result.Width := dmPelsWidth;
    Result.Height := dmPelsHeight;
    Result.RefRate := dmDisplayFrequency;
    Exit;
  end;
  {$ENDIF}

  //2. Try to use first available resolution
  if fCount > 0 then
  begin
    Result.Width := fItems[0].Width;
    Result.Height := fItems[0].Height;
    Result.RefRate := fItems[0].RefRate[0];
  end
  else
  //3. Fallback to windowed mode
  begin
    Result.Width := -1;
    Result.Height := -1;
    Result.RefRate := -1;
  end;
end;


//we need to set this IDs in settings, so we don't work on "physical" values
//and everything is kept inside this class, not in TMainSettings
function TKMResolutions.GetResolutionIDs(const aResolution: TKMScreenRes): TKMScreenResIndex;
var
  I, J: Integer;
begin
  Result.ResID := -1;
  Result.RefID := -1;

  for I := 0 to fCount - 1 do
    if (fItems[I].Width = aResolution.Width)
    and (fItems[I].Height = aResolution.Height) then
      for J := 0 to fItems[I].RefRateCount - 1 do
        if fItems[I].RefRate[J] = aResolution.RefRate then
        begin
          Result.ResID := I;
          Result.RefID := J;
          Exit;
        end;
end;


end.
