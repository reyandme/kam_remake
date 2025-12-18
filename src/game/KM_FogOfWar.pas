unit KM_FogOfWar;
{$I KaM_Remake.inc}
interface
uses
  Math, KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points;


// Fog of War state for each player
type
  TKMFogOfWarCommon = class
  public
    function CheckTileInitialRevelation(const X,Y: Word): Boolean; virtual; abstract;

    function CheckVerticeRevelation(const X,Y: Word): Byte; virtual; abstract;
    function CheckTileRevelation(const X,Y: Word): Byte; virtual; abstract;
    function CheckRevelation(const aPoint: TKMPointF): Byte; virtual; abstract;

    function CheckVerticeRenderRev(const X,Y: Word): Byte; virtual; abstract;
    function CheckTileRenderRev(const X,Y: Word): Byte; virtual; abstract;
    function CheckRenderRev(const aPoint: TKMPointF): Byte; virtual; abstract;
  end;

  TKMFogOfWar = class(TKMFogOfWarCommon)
  private
    fAnimStep: Cardinal;
    fMapX: Word;
    fMapY: Word;

    fDynamicFOW: Boolean; //Local copy for faster access, updated in UpdateState

    //Initial revealers from static script
    fInitialRevealAll: Boolean;
    fInitialRevealers: TKMPointTagList;

    // Used to optimize RevealCircle
    // It doesn't work if a cover function is called
    // No need to save/load it, it's just an optimisation
    fRevealedRadius: array [0..MAX_MAP_SIZE-1, 0..MAX_MAP_SIZE-1] of Word;
    fRenderRevRevealedRad: array [0..MAX_MAP_SIZE-1, 0..MAX_MAP_SIZE-1] of Word;
    fCoverHasBeenCalled: Boolean;
    fRevealedToMax: TBoolean2Array;

    (*Revelation: array of array of packed record
      //Lies within range 0, TERRAIN_FOG_OF_WAR_MIN..TERRAIN_FOG_OF_WAR_MAX.
      Visibility: Byte;
      {LastTerrain: Byte;
      LastHeight: Byte;
      LastObj: Byte;
      LastHouse: TKMHouseType;}
    end;*)
    procedure SetMapSize(aMapX, aMapY: Word);
    function CheckVerticeRev(aRevArray: PKMByte2Array; const X,Y: Word): Byte; inline;
    function CheckTileRev(aRevArray: PKMByte2Array; const X,Y: Word): Byte; inline;
    function CheckRev(aRevArray: PKMByte2Array; const aPoint: TKMPointF): Byte; inline;
  public
    Revelation: TKMByte2Array; //Public for faster access from Render
    RenderRevelation: TKMByte2Array; //Revelation for render - we have to render sprites a bit around actual FOW revelation

    constructor Create(aMapX, aMapY: Word; aDynamicFOW: Boolean);
    destructor Destroy; override;

    property InitialRevealAll: Boolean read fInitialRevealAll write fInitialRevealAll;
    property InitialRevealers: TKMPointTagList read fInitialRevealers;

    procedure RevealCircle(const aPos: TKMPoint; Radius,Amount: Word);
    procedure CoverCircle(const aPos: TKMPoint; Radius: Word);
    procedure RevealRect(const TL, BR: TKMPoint; Amount: Word);
    procedure CoverRect(const TL, BR: TKMPoint);
    procedure RevealEverything;
    procedure CoverEverything;

    function CheckTileInitialRevelation(const X,Y: Word): Boolean; override;

    function CheckVerticeRevelation(const X,Y: Word): Byte; override;
    function CheckTileRevelation(const X,Y: Word): Byte; override;
    function CheckRevelation(const aPoint: TKMPointF): Byte; override;

    function CheckVerticeRenderRev(const X,Y: Word): Byte; override;
    function CheckTileRenderRev(const X,Y: Word): Byte; override;
    function CheckRenderRev(const aPoint: TKMPointF): Byte; override;

    procedure SyncFOW(aFOW: TKMFogOfWar);

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    procedure UpdateState(aDynamicFOW: Boolean);
  end;

  // FOW that is always revealed (used by MapEd, Replays)
  TKMFogOfWarOpen = class(TKMFogOfWarCommon)
  public
    function CheckTileInitialRevelation(const X,Y: Word): Boolean; override;

    function CheckVerticeRevelation(const X,Y: Word): Byte; override;
    function CheckTileRevelation(const X,Y: Word): Byte; override;
    function CheckRevelation(const aPoint: TKMPointF): Byte; override;

    function CheckVerticeRenderRev(const X,Y: Word): Byte; override;
    function CheckTileRenderRev(const X,Y: Word): Byte; override;
    function CheckRenderRev(const aPoint: TKMPointF): Byte; override;
  end;


implementation
uses
  SysUtils, KM_DevPerfLog, KM_DevPerfLogTypes;

const
  // Addition to Revelation radius for Render revelation
  RENDER_RADIUS_ADD = 5; // 4 is not enough sometimes (Barracks?), 5 looks good


{ TKMFogOfWar }
// Init with Terrain size only once on creation as terrain size never change during the game
constructor TKMFogOfWar.Create(aMapX, aMapY: Word; aDynamicFOW: Boolean);
begin
  inherited Create;

  fInitialRevealAll := False;
  fInitialRevealers := TKMPointTagList.Create;
  SetMapSize(aMapX, aMapY);

  fDynamicFOW := aDynamicFOW;
end;


destructor TKMFogOfWar.Destroy;
begin
  FreeAndNil(fInitialRevealers);

  inherited;
end;


procedure TKMFogOfWar.SetMapSize(aMapX, aMapY: Word);
begin
  fMapX := aMapX;
  fMapY := aMapY;
  SetLength(fRevealedToMax, fMapY, fMapX);
  SetLength(Revelation, fMapY, fMapX);
  SetLength(RenderRevelation, fMapY, fMapX);
end;


// Reveal circle on map
// Amount controls how "strong" terrain is revealed, almost instantly or slowly frame-by-frame in multiple calls
procedure TKMFogOfWar.RevealCircle(const aPos: TKMPoint; Radius, Amount: Word);

  procedure RevealFor(aForRevelation: Boolean; aRadius, aAmount: Word);
  var
    I, K: Word;
    I1, I2, K1, K2: Word;
    sqrRadius, sqrI: Integer;
    revArray: PKMByte2Array;
  begin
    if aForRevelation then
      revArray := @Revelation
    else
      revArray := @RenderRevelation;

    //Avoid repeated computing (+2% performance)
    I1 := Max(aPos.Y-aRadius, 0);
    I2 := Min(aPos.Y+aRadius, fMapY-1);
    K1 := Max(aPos.X-aRadius, 0);
    K2 := Min(aPos.X+aRadius, fMapX-1);
    sqrRadius := Sqr(aRadius);

    //Inline maths here to gain performance
    if aAmount >= FOG_OF_WAR_MAX then
    begin
      for I := I1 to I2 do
      begin
        sqrI := Sqr(aPos.Y - I);
        for K := K1 to K2 do
          if (Sqr(aPos.X - K) + sqrI) <= sqrRadius then
          begin
            revArray^[I, K] := FOG_OF_WAR_MAX;
            if aForRevelation then
              fRevealedToMax[I, K] := True;
          end;
      end;
    end
    else
    begin
      for I := I1 to I2 do
      begin
        sqrI := Sqr(aPos.Y - I);
        for K := K1 to K2 do
          if (Sqr(aPos.X - K) + sqrI) <= sqrRadius then
          begin
            revArray^[I, K] := Min(revArray^[I, K] + aAmount, FOG_OF_WAR_MAX);
            if aForRevelation and (revArray^[I, K] = FOG_OF_WAR_MAX) then
              fRevealedToMax[I, K] := True;
          end;
      end;
    end;
  end;

var
  aroundRadius: Word;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psGameFOW);
  {$ENDIF}
  try
    aroundRadius := Radius + RENDER_RADIUS_ADD;
    if not fCoverHasBeenCalled and not fDynamicFOW then
    begin
      if fRevealedRadius[aPos.Y, aPos.X] < Radius then
      begin
        fRevealedRadius[aPos.Y, aPos.X] := Radius;
        RevealFor(True, Radius, Amount);
      end;
      if fRenderRevRevealedRad[aPos.Y, aPos.X] < aroundRadius then
      begin
        fRenderRevRevealedRad[aPos.Y, aPos.X] := aroundRadius;
        RevealFor(False, aroundRadius, FOG_OF_WAR_MAX);
      end;
    end else begin
      RevealFor(True, Radius, Amount);
      RevealFor(False, aroundRadius, FOG_OF_WAR_MAX);
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psGameFOW);
    {$ENDIF}
  end;
end;


procedure TKMFogOfWar.CoverCircle(const aPos: TKMPoint; Radius: Word);

  procedure CoverFor(aForRevelation: Boolean; aRadius: Word);
  var
    I, K: Word;
    I1, I2, K1, K2: Word;
    sqrRadius: Integer;
    revArray: PKMByte2Array;
  begin
    if aForRevelation then
      revArray := @Revelation
    else
      revArray := @RenderRevelation;

    // Avoid repeated computing (+2% performance)
    I1 := Max(aPos.Y-aRadius, 0);
    I2 := Min(aPos.Y+aRadius, fMapY-1);
    K1 := Max(aPos.X-aRadius, 0);
    K2 := Min(aPos.X+aRadius, fMapX-1);
    sqrRadius := Sqr(aRadius);

    //Inline maths here to gain performance
    for I := I1 to I2 do
      for K := K1 to K2 do
        if (Sqr(aPos.X - K) + Sqr(aPos.Y - I)) <= sqrRadius then
          revArray^[I,K] := 0;
  end;

begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psGameFOW);
  {$ENDIF}
  try
    CoverFor(True, Radius);
    CoverFor(False, Max(0, Integer(Radius) - RENDER_RADIUS_ADD));

    fCoverHasBeenCalled := True;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psGameFOW);
    {$ENDIF}
  end;
end;


procedure TKMFogOfWar.RevealRect(const TL, BR: TKMPoint; Amount: Word);
var
  I, K: Word;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psGameFOW);
  {$ENDIF}
  try
    for I := TL.Y to BR.Y do
      for K := TL.X to BR.X do
      begin
        Revelation[I,K] := Min(Revelation[I,K] + Amount, FOG_OF_WAR_MAX);
        if Revelation[I,K] = FOG_OF_WAR_MAX then
          fRevealedToMax[I,K] := True;
      end;

    // Reveal with bigger radius for AroundRevelation
    for I := Max(0, TL.Y - RENDER_RADIUS_ADD) to Min(fMapY - 1, BR.Y + RENDER_RADIUS_ADD) do
      for K := Max(0, TL.X - RENDER_RADIUS_ADD) to Min(fMapX - 1, BR.X + RENDER_RADIUS_ADD) do
        RenderRevelation[I,K] := FOG_OF_WAR_MAX;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psGameFOW);
    {$ENDIF}
  end;
end;


procedure TKMFogOfWar.CoverRect(const TL, BR: TKMPoint);
var
  I, K: Word;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psGameFOW);
  {$ENDIF}
  try
    for I := TL.Y to BR.Y do
      for K := TL.X to BR.X do
        Revelation[I,K] := 0;

    // Cover with smaller radius for AroundRevelation, as nearby could be reveled tiles
    for I := Min(fMapY - 1, TL.Y + RENDER_RADIUS_ADD) to Max(0, BR.Y - RENDER_RADIUS_ADD) do
      for K := Min(fMapX - 1, TL.X + RENDER_RADIUS_ADD) to Max(0, BR.X - RENDER_RADIUS_ADD) do
        RenderRevelation[I,K] := 0;

    fCoverHasBeenCalled := True;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psGameFOW);
    {$ENDIF}
  end;
end;


// Reveal whole map to max value
procedure TKMFogOfWar.RevealEverything;
var
  I, K: Word;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psGameFOW);
  {$ENDIF}
  try
    for I := 0 to fMapY - 1 do
      for K := 0 to fMapX - 1 do
      begin
        Revelation[I, K] := FOG_OF_WAR_MAX;
        RenderRevelation[I, K] := FOG_OF_WAR_MAX;
      end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psGameFOW);
    {$ENDIF}
  end;
end;


procedure TKMFogOfWar.CoverEverything;
var
  I, K: Word;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psGameFOW);
  {$ENDIF}
  try
    for I := 0 to fMapY - 1 do
      for K := 0 to fMapX - 1 do
      begin
        Revelation[I, K] := 0;
        RenderRevelation[I, K] := FOG_OF_WAR_MAX;
      end;

    fCoverHasBeenCalled := True;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psGameFOW);
    {$ENDIF}
  end;
end;


// Check if requested vertice is revealed for given player
// Return value of revelation is 0..255
// 0 unrevealed, 255 revealed completely
// but False in cases where it will effect the gameplay (e.g. unit hit test)
function TKMFogOfWar.CheckVerticeRev(aRevArray: PKMByte2Array; const X,Y: Word): Byte;
var
  F: Byte;
begin
  // I like how "alive" the fog looks with some tweaks
  // pulsating around units and slowly thickening when they leave :)
  F := aRevArray^[Y,X];
  if fDynamicFOW then
    if (F >= FOG_OF_WAR_ACT) then
      Result := 255
    else
      Result := (F shl 8) div FOG_OF_WAR_ACT
  else
    if (F >= FOG_OF_WAR_MIN) then
      Result := 255
    else
      Result := 0;
end;


function TKMFogOfWar.CheckVerticeRevelation(const X, Y: Word): Byte;
begin
  Result := CheckVerticeRev(@Revelation, X, Y);
end;


function TKMFogOfWar.CheckRevelation(const aPoint: TKMPointF): Byte;
begin
  Result := CheckRev(@Revelation, aPoint);
end;


function TKMFogOfWar.CheckTileRevelation(const X, Y: Word): Byte;
begin
  Result := CheckTileRev(@Revelation, X, Y);
end;


function TKMFogOfWar.CheckVerticeRenderRev(const X, Y: Word): Byte;
begin
  Result := CheckVerticeRev(@RenderRevelation, X, Y);
end;


function TKMFogOfWar.CheckTileRenderRev(const X, Y: Word): Byte;
begin
  Result := CheckTileRev(@RenderRevelation, X, Y);
end;


function TKMFogOfWar.CheckRenderRev(const aPoint: TKMPointF): Byte;
begin
  Result := CheckRev(@RenderRevelation, aPoint);
end;


function TKMFogOfWar.CheckTileInitialRevelation(const X,Y: Word): Boolean;
var
  I: Integer;
  P: TKMPoint;
begin
  if fInitialRevealAll then
    Exit(True);

  Result := False;
  P := TKMPoint.New(X, Y);
  for I := 0 to fInitialRevealers.Count - 1 do
    Result := Result or (KMDistanceSqr(P, fInitialRevealers[I]) < Sqr(fInitialRevealers.Tag[I]));
end;


// Check if requested tile is revealed for given player
// Input values for tiles (X,Y) are in 1..N range
// Return value of revelation within 0..255 (0 unrevealed, 255 fully revealed)
// but False in cases where it will effect the gameplay (e.g. unit hit test)
function TKMFogOfWar.CheckTileRev(aRevArray: PKMByte2Array; const X,Y: Word): Byte;
begin
  if (X <= 0) or (X >= fMapX)
    or (Y <= 0) or (Y >= fMapY) then
    Exit(0);

  // Check all four corners and choose max
  Result := CheckVerticeRev(aRevArray,X-1,Y-1);
  if Result = 255 then Exit;

  Result := Max(Result, CheckVerticeRev(aRevArray,X,Y-1));
  if Result = 255 then Exit;

  Result := Max(Result, CheckVerticeRev(aRevArray,X,Y));
  if Result = 255 then Exit;

  Result := Max(Result, CheckVerticeRev(aRevArray,X-1,Y));
end;


// Check exact revelation of the point (interpolate between vertices)
function TKMFogOfWar.CheckRev(aRevArray: PKMByte2Array; const aPoint: TKMPointF): Byte;
var
  A, B, C, D, Y1, Y2: Byte;
begin
  if (aPoint.X <= 0) or (aPoint.X >= fMapX - 1)
    or (aPoint.Y <= 0) or (aPoint.Y >= fMapY - 1) then
    Exit(0);

  //Interpolate as follows:
  //A-B
  //C-D
  A := CheckVerticeRev(aRevArray, Trunc(aPoint.X),   Trunc(aPoint.Y)   );
  B := CheckVerticeRev(aRevArray, Trunc(aPoint.X)+1, Trunc(aPoint.Y)   );
  C := CheckVerticeRev(aRevArray, Trunc(aPoint.X),   Trunc(aPoint.Y)+1 );
  D := CheckVerticeRev(aRevArray, Trunc(aPoint.X)+1, Trunc(aPoint.Y)+1 );

  Y1 := Round(A + (B - A) * Frac(aPoint.X));
  Y2 := Round(C + (D - C) * Frac(aPoint.X));

  Result := Round(Y1 + (Y2 - Y1) * Frac(aPoint.Y));
end;


// Synchronize FOW revelation between players
procedure TKMFogOfWar.SyncFOW(aFOW: TKMFogOfWar);
var
  I, K: Word;
begin
  for I := 0 to fMapY - 1 do
    for K := 0 to fMapX - 1 do
    begin
      Revelation[I, K] := Max(Revelation[I, K], aFOW.Revelation[I, K]);
      RenderRevelation[I, K] := Max(RenderRevelation[I, K], aFOW.RenderRevelation[I, K]);
    end;
end;


procedure TKMFogOfWar.Save(SaveStream: TKMemoryStream);
var
  I: Word;
begin
  SaveStream.PlaceMarker('FOW');
  SaveStream.Write(fAnimStep);
  SaveStream.Write(fInitialRevealAll);
  fInitialRevealers.SaveToStream(SaveStream);
  //Because each player has FOW it can become a bottleneck (8.7ms per run) due to autosaving (e.g. on Paradise Island)
  //so save it out 1 row at a time (due to 2D arrays not being continguous we can't save it all at once)
  for I := 0 to fMapY - 1 do
  begin
    SaveStream.Write(fRevealedToMax[I, 0], fMapX * SizeOf(fRevealedToMax[I, 0]));
    SaveStream.Write(Revelation[I, 0], fMapX * SizeOf(Revelation[I, 0]));
    SaveStream.Write(RenderRevelation[I, 0], fMapX * SizeOf(RenderRevelation[I, 0]));
  end;
end;


procedure TKMFogOfWar.Load(LoadStream: TKMemoryStream);
var
  I: Word;
begin
  LoadStream.CheckMarker('FOW');
  LoadStream.Read(fAnimStep);
  LoadStream.Read(fInitialRevealAll);
  fInitialRevealers.LoadFromStream(LoadStream);

  SetMapSize(fMapX, fMapY);
  for I := 0 to fMapY - 1 do
  begin
    LoadStream.Read(fRevealedToMax[I, 0], fMapX * SizeOf(fRevealedToMax[I, 0]));
    LoadStream.Read(Revelation[I, 0], fMapX * SizeOf(Revelation[I, 0]));
    LoadStream.Read(RenderRevelation[I, 0], fMapX * SizeOf(RenderRevelation[I, 0]));
  end;
end;


//Decrease FOW revelation as time goes
procedure TKMFogOfWar.UpdateState(aDynamicFOW: Boolean);
var
  I, K: Word;
begin
  fDynamicFOW := aDynamicFOW;
  if not fDynamicFOW then Exit;

  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psGameFOW);
  {$ENDIF}
  try
    Inc(fAnimStep);

    for I := 0 to fMapY - 1 do
      for K := 0 to fMapX - 1 do
        if {(Revelation[I, K] > 0)//(Revelation[I, K] > FOG_OF_WAR_MIN)
          and }((I * fMapX + K + fAnimStep) mod FOW_PACE = 0) then
        begin
          if (Revelation[I, K] > FOG_OF_WAR_MAX - FOG_OF_WAR_DEC) then
          begin
            if not fRevealedToMax[I, K] then
              Revelation[I, K] := Max(0, Revelation[I, K] - FOG_OF_WAR_DEC)
            else
              fRevealedToMax[I, K] := False;
          end else
            Revelation[I, K] := Max(0, Revelation[I, K] - FOG_OF_WAR_DEC);


          {//Remember what we have seen last
          if Revelation[I, K].Visibility <= FOG_OF_WAR_MIN then
          begin
            Revelation[I, K].LastTerrain := gTerrain.Land^[I, K].BaseLayer.Terrain;

          end;}
        end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psGameFOW);
    {$ENDIF}
  end;
end;


{ TKMFogOfWarOpen }
function TKMFogOfWarOpen.CheckTileInitialRevelation(const X,Y: Word): Boolean;
begin
  Result := True;
end;

function TKMFogOfWarOpen.CheckRenderRev(const aPoint: TKMPointF): Byte;
begin
  Result := FOG_OF_WAR_MAX;
end;

function TKMFogOfWarOpen.CheckRevelation(const aPoint: TKMPointF): Byte;
begin
  Result := FOG_OF_WAR_MAX;
end;

function TKMFogOfWarOpen.CheckTileRenderRev(const X, Y: Word): Byte;
begin
  Result := FOG_OF_WAR_MAX;
end;

function TKMFogOfWarOpen.CheckTileRevelation(const X, Y: Word): Byte;
begin
  Result := FOG_OF_WAR_MAX;
end;

function TKMFogOfWarOpen.CheckVerticeRenderRev(const X, Y: Word): Byte;
begin
  Result := FOG_OF_WAR_MAX;
end;

function TKMFogOfWarOpen.CheckVerticeRevelation(const X, Y: Word): Byte;
begin
  Result := FOG_OF_WAR_MAX;
end;


end.
