unit KM_SoftShadows;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Math,
  KM_ResSprites, KM_ResTypes;

type
  TKMSoftShadowConverter = class
  private
    // We will be working with the data by this pointer
    fRXData: PRXData;

    fOnlyShadows: boolean;
    fTempShadowMap: array {Y} of array {X} of Boolean;
    fShadowMap: array {Y} of array {X} of Boolean;

    function ReadPixel(const aIndex, aX, aY: Integer): Cardinal; inline;
    function ReadPixelSafe(const aIndex, aX, aY: Integer): Cardinal; inline;

    function IsBlack(aColor: Cardinal): Boolean; inline;
    function IsTransparent(aColor: Cardinal): Boolean; inline;
    function IsObject(aColor: Cardinal): Boolean; inline;
    function IsTransparentOrObject(aColor: Cardinal): Boolean; inline;
    function IsShadow(aIndex, aX, aY: Integer): Boolean;
    procedure PrepareShadows(aIndex: Word; aOnlyShadows: Boolean);

    function IsShadowPixel(aIndex, aX, aY: Word): Boolean; inline;
    function IsObjectPixel(aIndex, aX, aY: Word): Boolean; inline;
  public
    constructor Create(aRXData: PRXData);
    procedure ConvertShadows(aIndex: Word; aOnlyShadows: Boolean);
    procedure DetermineImageObjectSize(aIndex: Word);
    procedure RemoveShadow(aIndex: Word; aByMask: Boolean);
  end;


implementation
const
  BLUR_RADIUS = 2.0; //Amount of blurring applied on shadow edges
  SHADING_LEVEL = 150; //Alpha value for full shadow (0..255)


{ TKMSoftShadowConverter }
constructor TKMSoftShadowConverter.Create(aRXData: PRXData);
begin
  inherited Create;

  fRXData := aRXData;
end;


function TKMSoftShadowConverter.ReadPixel(const aIndex, aX, aY: Integer): Cardinal;
begin
  Result := fRXData.RGBA[aIndex, aY * fRXData.Size[aIndex].X + aX];
end;


function TKMSoftShadowConverter.ReadPixelSafe(const aIndex, aX, aY: Integer): Cardinal;
begin
  if (aX < 0) or (aY < 0) or (aX >= fRXData.Size[aIndex].X) or (aY >= fRXData.Size[aIndex].Y) then
    Result := 0
  else
    Result := ReadPixel(aIndex, aX, aY);
end;


//Maybe the definition of black will change later (to include almost black colors?)
function TKMSoftShadowConverter.IsBlack(aColor: Cardinal): Boolean;
begin
  if fOnlyShadows then
    Result := (aColor = $FF000000) //Only black areas
  else
    Result := (aColor and $FF000000) <> 0; //Everything that's not transparent
end;


//Maybe the definition of transparent will change later
function TKMSoftShadowConverter.IsTransparent(aColor: Cardinal): Boolean;
begin
  Result := (aColor shr 24 = 0);
end;


//Pixels that are not transparent and not black are an object (part of actual sprite)
function TKMSoftShadowConverter.IsObject(aColor: Cardinal): Boolean;
begin
  Result := not IsTransparent(aColor) and not IsBlack(aColor);
end;


function TKMSoftShadowConverter.IsTransparentOrObject(aColor: Cardinal): Boolean;
begin
  Result := IsTransparent(aColor) or not IsBlack(aColor);
end;


function TKMSoftShadowConverter.IsShadow(aIndex, aX, aY: Integer): Boolean;
var
  colorThis, colorLeft, colorRight, colorTop, colorBottom: Cardinal;
begin
  colorThis   := ReadPixelSafe(aIndex, aX,   aY);
  colorLeft   := ReadPixelSafe(aIndex, aX-1, aY);
  colorRight  := ReadPixelSafe(aIndex, aX+1, aY);
  colorTop    := ReadPixelSafe(aIndex, aX,   aY-1);
  colorBottom := ReadPixelSafe(aIndex, aX,   aY+1);

  Result := False;

  if IsBlack(colorThis) then
  begin
    if IsTransparent(colorLeft) or IsTransparent(colorRight)
    or IsTransparent(colorTop)  or IsTransparent(colorBottom) then
      Result := (
                  Ord(IsTransparentOrObject(colorLeft)) +
                  Ord(IsTransparentOrObject(colorRight)) +
                  Ord(IsTransparentOrObject(colorTop)) +
                  Ord(IsTransparentOrObject(colorBottom))
                ) > 2;
  end else
  if IsTransparent(colorThis) then
  begin
    if IsBlack(colorLeft) or IsBlack(colorRight)
    or IsBlack(colorTop)  or IsBlack(colorBottom) then
      Result := (
                  Ord(not IsTransparent(colorLeft)) +
                  Ord(not IsTransparent(colorRight)) +
                  Ord(not IsTransparent(colorTop)) +
                  Ord(not IsTransparent(colorBottom))
                ) > 2;
  end;
end;


function TKMSoftShadowConverter.IsShadowPixel(aIndex, aX, aY: Word): Boolean;
begin
  var Color := ReadPixel(aIndex, aX, aY);
  Result := (fTempShadowMap[aY, aX] or fShadowMap[aY, aX] or IsTransparent(Color)) and not IsObject(Color);
end;


function TKMSoftShadowConverter.IsObjectPixel(aIndex, aX, aY: Word): Boolean;
begin
  var Color := ReadPixel(aIndex, aX, aY);
  Result := IsObject(Color) and not fTempShadowMap[aY, aX] and not fShadowMap[aY, aX];
end;


procedure TKMSoftShadowConverter.DetermineImageObjectSize(aIndex: Word);
var
  K,I: Integer;
begin
  PrepareShadows(aIndex, True);

  fRXData.SizeNoShadow[aIndex].Left := fRXData.Size[aIndex].X - 1;
  fRXData.SizeNoShadow[aIndex].Right := 0;
  fRXData.SizeNoShadow[aIndex].Top := fRXData.Size[aIndex].Y - 1;
  fRXData.SizeNoShadow[aIndex].Bottom := 0;

  for I := 0 to fRXData.Size[aIndex].Y - 1 do
  for K := 0 to fRXData.Size[aIndex].X - 1 do
  if IsObjectPixel(aIndex, K, I) then
  begin
    fRXData.SizeNoShadow[aIndex].Left := Min(fRXData.SizeNoShadow[aIndex].Left, K);
    fRXData.SizeNoShadow[aIndex].Right := Max(fRXData.SizeNoShadow[aIndex].Right, K);
    fRXData.SizeNoShadow[aIndex].Top := Min(fRXData.SizeNoShadow[aIndex].Top, I);
    fRXData.SizeNoShadow[aIndex].Bottom := Max(fRXData.SizeNoShadow[aIndex].Bottom, I);
  end;
end;


//RemoveShadow via removing its mask
procedure TKMSoftShadowConverter.RemoveShadow(aIndex: Word; aByMask: Boolean);
var
  I, K: Integer;
begin
  PrepareShadows(aIndex, False);

  for I := 0 to fRXData.Size[aIndex].Y - 1 do
  for K := 0 to fRXData.Size[aIndex].X - 1 do
  if IsShadowPixel(aIndex, K, I) then
    if aByMask then
      fRXData.Mask[aIndex, I * fRXData.Size[aIndex].X + K] := 0 //Remove mask image outside of object
    else
      fRXData.RGBA[aIndex, I * fRXData.Size[aIndex].X + K] := 0;
end;


procedure TKMSoftShadowConverter.ConvertShadows(aIndex: Word; aOnlyShadows: Boolean);

  function GetBlurredShadow(X,Y: Integer): Single;
  var
    iX, iY, XDiff, YDiff, BlurCeil: Integer;
    Distance, Multiplier, Divisor, Ret: Single;
    Shadow, WasRealShadow: Boolean;
  begin
    WasRealShadow := False;
    Ret := 0;
    Divisor := 0;
    BlurCeil := Ceil(BLUR_RADIUS);
    for iY := Y - BlurCeil to Y + BlurCeil do
    for iX := X - BlurCeil to X + BlurCeil do
    begin
      XDiff := iX-X;
      YDiff := iY-Y;
      Distance := Sqrt(XDiff*XDiff + YDiff*YDiff);
      Multiplier := BLUR_RADIUS - Distance;

      if Multiplier > 0 then
      begin
        Divisor := Divisor + Multiplier;
        if (iX < 0) or (iY < 0) or (iX >= fRXData.Size[aIndex].X) or (iY >= fRXData.Size[aIndex].Y) then
          Continue;
        Shadow := fShadowMap[iY, iX];
        if Shadow then WasRealShadow := True;
        if not IsTransparent(ReadPixelSafe(aIndex, iX, iY)) then Shadow := True;
        if Shadow then Ret := Ret + Multiplier;
      end;
    end;

    if not WasRealShadow then
      Result := 0
    else
      Result := Ret / Divisor;
  end;

  function GetAverageColor(aColors: array of Cardinal): Cardinal;
  var
    I, accR, accG, accB, count: Cardinal;
  begin
    accR := 0;
    accB := 0;
    accG := 0;
    count := 0;
    for I := 0 to Length(aColors) - 1 do
      if aColors[I] and $FF000000 <> 0 then
      begin
        accR := accR + (aColors[I] and $FF);
        accG := accG + (aColors[I] shr 8 and $FF);
        accB := accB + (aColors[I] shr 16 and $FF);
        Inc(count);
      end;

    Result := 0;
    if count = 0 then Exit;
    accR := accR div count;
    accB := accB div count;
    accG := accG div count;

    Result := (accR + accG shl 8 + accB shl 16);
  end;

var
  I,K: Integer;
  originalColor: Cardinal;
  RealShadow: Byte;
  tempTarget: array of Cardinal;
  sx, sy: Word;
begin
  PrepareShadows(aIndex, aOnlyShadows);

  originalColor := 0;

  // We should not be reading from and writing to the same image, as writes affect the subsequent reads
  // Blit whole image in one go (and doctor shadows per-pixel further down the line)
  SetLength(tempTarget, fRXData.Size[aIndex].Y * fRXData.Size[aIndex].X);
  Move(fRXData.RGBA[aIndex, 0], tempTarget[0], Length(tempTarget) * SizeOf(Cardinal));

  for I := 0 to fRXData.Size[aIndex].Y - 1 do
  for K := 0 to fRXData.Size[aIndex].X - 1 do
  if IsShadowPixel(aIndex, K, I) then
  begin
    RealShadow := Min(Round(GetBlurredShadow(K, I) * SHADING_LEVEL), 255);

    // If we're doing the entire sprite consider the original color, else use black
    if not fOnlyShadows then
    begin
      originalColor := fRXData.RGBA[aIndex, I * fRXData.Size[aIndex].X + K];

      if (originalColor and $FF000000) = 0 then
      begin
        // Local vars for cache and neater code
        sx := fRXData.Size[aIndex].X;
        sy := fRXData.Size[aIndex].Y;

        // Take a blend of all the surrounding colors and use that to fill in gaps
        originalColor := GetAverageColor([fRXData.RGBA[aIndex, Max(I-1, 0   ) * sx + K],
                                          fRXData.RGBA[aIndex, Min(I+1, sy-1) * sx + K],
                                          fRXData.RGBA[aIndex, I              * sx + Max(K-1, 0)],
                                          fRXData.RGBA[aIndex, I              * sx + Min(K+1, sx-1)],
                                          // Diagonals
                                          fRXData.RGBA[aIndex, Max(I-1, 0   ) * sx + Min(K+1, sx-1)],
                                          fRXData.RGBA[aIndex, Min(I+1, sy-1) * sx + Max(K-1, 0)],
                                          fRXData.RGBA[aIndex, Max(I-1, 0   ) * sx + Max(K-1, 0)],
                                          fRXData.RGBA[aIndex, Min(I+1, sy-1) * sx + Min(K+1, sx-1)]]);
      end else
        originalColor := originalColor and $00FFFFFF;
    end;

    tempTarget[I * fRXData.Size[aIndex].X + K] := (RealShadow shl 24) or originalColor;
  end;

  // Blit image with softened shadows back
  Move(tempTarget[0], fRXData.RGBA[aIndex, 0], Length(tempTarget) * SizeOf(Cardinal));
end;


procedure TKMSoftShadowConverter.PrepareShadows(aIndex: Word; aOnlyShadows: Boolean);

  function ReadTempShadowMapSafe(aX, aY: Integer): Boolean;
  begin
    if (aX < 0) or (aY < 0) or (aX >= fRXData.Size[aIndex].X) or (aY >= fRXData.Size[aIndex].Y) then
      Result := False
    else
      Result := fTempShadowMap[aY, aX];
  end;

  function IsShadowOrObject(aX, aY: Integer): Boolean;
  begin
    if (aX < 0) or (aY < 0) or (aX >= fRXData.Size[aIndex].X) or (aY >= fRXData.Size[aIndex].Y) then
      Result := False
    else
      Result := fTempShadowMap[aY, aX] or IsObject(ReadPixel(aIndex, aX, aY));
  end;

  function ShadowsNearby(aX, aY: Integer): Byte;
  begin
    Result := 0;
    if ReadTempShadowMapSafe(aX-1, aY  )
    or ReadTempShadowMapSafe(aX+1, aY  )
    or ReadTempShadowMapSafe(aX,   aY-1)
    or ReadTempShadowMapSafe(aX,   aY+1) then
      Result := Ord(IsShadowOrObject(aX-1, aY  )) +
                Ord(IsShadowOrObject(aX+1, aY  )) +
                Ord(IsShadowOrObject(aX,   aY-1)) +
                Ord(IsShadowOrObject(aX,   aY+1));
  end;

var
  I, K: Integer;
  Shadow: Boolean;
begin
  fOnlyShadows := aOnlyShadows;

  SetLength(fTempShadowMap, 0);
  SetLength(fShadowMap,     0);

  SetLength(fTempShadowMap, fRXData.Size[aIndex].Y, fRXData.Size[aIndex].X);
  SetLength(fShadowMap,     fRXData.Size[aIndex].Y, fRXData.Size[aIndex].X);

  for I := 0 to fRXData.Size[aIndex].Y - 1 do
  for K := 0 to fRXData.Size[aIndex].X - 1 do
    fTempShadowMap[I, K] := IsShadow(aIndex, K, I);

  for I := 0 to fRXData.Size[aIndex].Y - 1 do
  for K := 0 to fRXData.Size[aIndex].X - 1 do
  begin
    Shadow := fTempShadowMap[I, K];

    if Shadow and not IsObject(ReadPixel(aIndex, K, I))
    and (ShadowsNearby(K, I) = 1) then
      Shadow := False;

    fShadowMap[I, K] := Shadow;
  end;
end;


end.

