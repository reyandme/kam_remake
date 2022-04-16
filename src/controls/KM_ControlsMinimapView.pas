unit KM_ControlsMinimapView;
{$I KaM_Remake.inc}
interface
uses
  Classes, Controls,
  KromOGLUtils,
  KM_RenderUI, KM_Minimap, KM_Viewport,
  KM_ResFonts, KM_CommonTypes, KM_Points, KM_Defaults,
  KM_Controls, KM_ControlsBase;


type
  // MinimapView relies on fMinimap and fViewport that provide all the data
  // MinimapView itself is just a painter
  TKMMinimapView = class(TKMControl)
  private
    fBevel: TKMBevel;
    fMinimap: TKMMinimap;
    fView: TKMViewport;
    fPaintWidth: Integer;
    fPaintHeight: Integer;
    fLeftOffset: Integer;
    fTopOffset: Integer;

    fMapTex: TTexture;
    fWidthPOT: Word;
    fHeightPOT: Word;

    fOnChange, fOnMinimapClick: TPointEvent;
    fShowLocs: Boolean;
    fLocRad: Byte;
    fClickableOnce: Boolean;
    procedure UpdateTexture;
    procedure ResizeMinimap;
  protected
    procedure SetAnchors(aValue: TKMAnchorsSet); override;
  public
    OnLocClick: TIntegerEvent;

    constructor Create(aMinimap: TKMMinimap; aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aWithBevel: Boolean = False);

    function LocalToMapCoords(X,Y: Integer): TKMPoint;
    function MapCoordsToLocal(X,Y: Single; const Inset: ShortInt = 0): TKMPoint;
    procedure UpdateSizes;
    procedure SetViewport(aViewport: TKMViewport);
    property ShowLocs: Boolean read fShowLocs write fShowLocs;
    property ClickableOnce: Boolean read fClickableOnce write fClickableOnce;
    property OnChange: TPointEvent write fOnChange;
    property OnMinimapClick: TPointEvent read fOnMinimapClick write fOnMinimapClick;

    procedure MouseDown(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
    procedure MouseUp(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
    procedure MouseMove(X,Y: Integer; Shift: TShiftState); override;
    procedure Paint; override;
  end;


implementation
uses
  SysUtils,
  Math,
  KromUtils,
  KM_MinimapGame,
  KM_Render, KM_RenderTypes,
  KM_CommonUtils,
  KM_GameSettings, KM_InterfaceTypes;


{ TKMMinimapView }
constructor TKMMinimapView.Create(aMinimap: TKMMinimap; aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aWithBevel: Boolean = False);
begin
  //Create Bevel first
  if aWithBevel then
    fBevel := TKMBevel.Create(aParent, aLeft - 4, aTop - 4, aWidth + 8, aHeight + 8);

  //Then Minimap control itself
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight);

  //Radius of circle around player location
  fLocRad := 8;

  fMinimap := aMinimap;
  if fMinimap <> nil then
  begin
    fMinimap.SubOnUpdateTexture(UpdateTexture);
    fMinimap.SubOnResize(ResizeMinimap);

    fMapTex.Tex := TRender.GenerateTextureCommon(ftNearest, ftNearest);
  end;
end;


procedure TKMMinimapView.UpdateSizes;
begin
  if fMinimap.MapX > fMinimap.MapY then
  begin
    fPaintWidth := Width;
    fPaintHeight := Round(Height * fMinimap.MapY / Max(fMinimap.MapX, 1)); // X could = 0
    fLeftOffset := 0;
    fTopOffset := (Height - fPaintHeight) div 2;
  end
  else
  begin
    fPaintWidth := Round(Width * fMinimap.MapX / Max(fMinimap.MapY, 1)); // Y could = 0
    fPaintHeight := Height;
    fLeftOffset := (Width - fPaintWidth) div 2;
    fTopOffset := 0;
  end;
end;


procedure TKMMinimapView.SetViewport(aViewport: TKMViewport);
begin
  fView := aViewport;
end;


procedure TKMMinimapView.ResizeMinimap;
begin
  if Self = nil then Exit;

  fWidthPOT := MakePOT(fMinimap.MapX);
  fHeightPOT := MakePOT(fMinimap.MapY);
  fMapTex.U := fMinimap.MapX / fWidthPOT;
  fMapTex.V := fMinimap.MapY / fHeightPOT;
end;


procedure TKMMinimapView.UpdateTexture;
var
  wData: Pointer;
  I: Word;
begin
  if Self = nil then Exit;

  GetMem(wData, fWidthPOT * fHeightPOT * 4);

  if fMinimap.MapY > 0 then //if MapY = 0 then loop will overflow to MaxWord
  for I := 0 to fMinimap.MapY - 1 do
    Move(Pointer(NativeUint(fMinimap.Base) + I * fMinimap.MapX * 4)^,
         Pointer(NativeUint(wData) + I * fWidthPOT * 4)^, fMinimap.MapX * 4);

  TRender.UpdateTexture(fMapTex.Tex, fWidthPOT, fHeightPOT, tfRGBA8, wData);
  FreeMem(wData);

  UpdateSizes;
end;


function TKMMinimapView.LocalToMapCoords(X,Y: Integer): TKMPoint;
begin
  Result.X := EnsureRange(Trunc((X - AbsLeft - fLeftOffset) * (fMinimap.MapX + 1) / fPaintWidth),  1, fMinimap.MapX);
  Result.Y := EnsureRange(Trunc((Y - AbsTop  - fTopOffset ) * (fMinimap.MapY + 1) / fPaintHeight), 1, fMinimap.MapY);
end;


function TKMMinimapView.MapCoordsToLocal(X,Y: Single; const Inset: ShortInt = 0): TKMPoint;
begin
  Assert(Inset >= -1, 'Min allowed inset is -1, to be within TKMPoint range of 0..n');
  Result.X := AbsLeft + fLeftOffset + EnsureRange(Round(X * fPaintWidth /  fMinimap.MapX), Inset, fPaintWidth  - Inset);
  Result.Y := AbsTop  + fTopOffset  + EnsureRange(Round(Y * fPaintHeight / fMinimap.MapY), Inset, fPaintHeight - Inset);
end;


procedure TKMMinimapView.SetAnchors(aValue: TKMAnchorsSet);
begin
  inherited;

  if fBevel <> nil then
    fBevel.Anchors := aValue;
end;


procedure TKMMinimapView.MouseDown(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  inherited;

  MouseMove(X,Y,Shift);
end;


procedure TKMMinimapView.MouseMove(X,Y: Integer; Shift: TShiftState);
var
  viewPos: TKMPoint;
begin
  inherited;

  if (ssLeft in Shift) and not fClickableOnce then
  begin
    viewPos := LocalToMapCoords(X,Y);
    if Assigned(fOnChange) then
      fOnChange(Self, viewPos.X, viewPos.Y);
  end;
end;


procedure TKMMinimapView.MouseUp(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
var
  I: Integer;
  T, viewPos: TKMPoint;
begin
  inherited;

  if fClickableOnce then
  begin
    fClickableOnce := False; //Not clickable anymore
    viewPos := LocalToMapCoords(X,Y);
    if Assigned(fOnMinimapClick) then
      fOnMinimapClick(Self, viewPos.X, viewPos.Y);
  end;

  if fShowLocs then
  for I := 0 to MAX_HANDS - 1 do
  if fMinimap.HandShow[I] and not KMSamePoint(fMinimap.HandLocs[I], KMPOINT_ZERO) then
  begin
    T := MapCoordsToLocal(fMinimap.HandLocs[I].X, fMinimap.HandLocs[I].Y, fLocRad);
    if Sqr(T.X - X) + Sqr(T.Y - Y) < Sqr(fLocRad) then
    begin
      if Assigned(OnLocClick) then
        OnLocClick(I);

      //Do not repeat events for stacked locations
      Break;
    end;
  end;
end;


procedure TKMMinimapView.Paint;
const
  ALERT_RAD = 4;
var
  I, K: Integer;
  R: TKMRect;
  S: TKMDirection4Set;
  T, T1, T2: TKMPoint;
  minimapGame: TKMMiniMapGame;
  miniLeft, miniTop, miniRight, miniBottom: SmallInt;
begin
  inherited;

  if (fMinimap = nil) or (fMinimap.MapX * fMinimap.MapY = 0) then
    Exit;

  if (fMapTex.Tex <> 0) then
    TKMRenderUI.WriteTexture(AbsLeft + fLeftOffset, AbsTop + fTopOffset, fPaintWidth, fPaintHeight, fMapTex, $FFFFFFFF)
  else
    TKMRenderUI.WriteBevel(AbsLeft, AbsTop, Width, Height);

  //Alerts (under viewport rectangle)
  if fMinimap is TKMMiniMapGame then
  begin
    minimapGame := TKMMiniMapGame(fMinimap);

    if (minimapGame.Alerts <> nil) then
    for I := 0 to minimapGame.Alerts.Count - 1 do
    if minimapGame.Alerts[I].VisibleMinimap then
    begin
      T := MapCoordsToLocal(minimapGame.Alerts[I].Loc.X, minimapGame.Alerts[I].Loc.Y, ALERT_RAD);
      TKMRenderUI.WritePicture(T.X, T.Y, 0, 0, [],
                               minimapGame.Alerts[I].TexMinimap.RX, minimapGame.Alerts[I].TexMinimap.ID,
                               True, minimapGame.Alerts[I].TeamColor, Abs((TimeGet mod 1000) / 500 - 1));
    end;

    //Viewport rectangle
    if fView <> nil then
    begin
      R := fView.GetMinimapClip;
      if (R.Right - R.Left) * (R.Bottom - R.Top) > 0 then
      begin
        if gGameSettings.ZoomBehaviour = zbRestricted then
        begin
          TKMRenderUI.WriteOutline(AbsLeft + fLeftOffset + Round((R.Left - 1)*fPaintWidth / fMinimap.MapX),
                                   AbsTop  + fTopOffset  + Round((R.Top - 1)*fPaintHeight / fMinimap.MapY),
                                   Round((R.Right - R.Left)*fPaintWidth / fMinimap.MapX),
                                   Round((R.Bottom - R.Top)*fPaintHeight / fMinimap.MapY), 1, $FFFFFFFF);
        end
        else
        begin
          miniLeft := AbsLeft + fLeftOffset + Round((R.Left - 1)*fPaintWidth / fMinimap.MapX) + 1;
          miniTop := AbsTop + fTopOffset  + Round((R.Top - 1)*fPaintHeight / fMinimap.MapY) + 1;
          miniRight := AbsLeft + fLeftOffset + Round((R.Right - 1)*fPaintWidth / fMinimap.MapX);
          miniBottom := AbsTop + fTopOffset  + Round((R.Bottom - 1)*fPaintHeight / fMinimap.MapY);

          S := fView.GetMinimapClipLines;
          if drW in S then
            TKMRenderUI.WriteLine(miniLeft, miniBottom, miniLeft, miniTop, $FFFFFFFF);
          if drN in S then
            TKMRenderUI.WriteLine(miniLeft-1, miniTop, miniRight, miniTop, $FFFFFFFF);
          if drE in S then
            TKMRenderUI.WriteLine(miniRight, miniBottom, miniRight, miniTop, $FFFFFFFF);
          if drS in S then
            TKMRenderUI.WriteLine(miniLeft-1, miniBottom, miniRight, miniBottom, $FFFFFFFF);
        end;
      end;
    end;
  end;

  if fShowLocs then
  begin
    //Connect allied players
    for I := 0 to MAX_HANDS - 1 do
    if fMinimap.HandShow[I] and not KMSamePoint(fMinimap.HandLocs[I], KMPOINT_ZERO) then
      for K := I + 1 to MAX_HANDS - 1 do
      if fMinimap.HandShow[K] and not KMSamePoint(fMinimap.HandLocs[K], KMPOINT_ZERO) then
        if (fMinimap.HandTeam[I] <> 0) and (fMinimap.HandTeam[I] = fMinimap.HandTeam[K]) then
        begin
          T1 := MapCoordsToLocal(fMinimap.HandLocs[I].X, fMinimap.HandLocs[I].Y, fLocRad);
          T2 := MapCoordsToLocal(fMinimap.HandLocs[K].X, fMinimap.HandLocs[K].Y, fLocRad);
          TKMRenderUI.WriteLine(T1.X, T1.Y, T2.X, T2.Y, $FFFFFFFF);
        end;

    //Draw all the circles, THEN all the numbers so the numbers are not covered by circles when they are close
    for I := 0 to MAX_HANDS - 1 do
    if fMinimap.HandShow[I] and not KMSamePoint(fMinimap.HandLocs[I], KMPOINT_ZERO) then
    begin
      T := MapCoordsToLocal(fMinimap.HandLocs[I].X, fMinimap.HandLocs[I].Y, fLocRad);
      TKMRenderUI.WriteCircle(T.X, T.Y, fLocRad, fMinimap.HandColors[I]);
    end;

    for I := 0 to MAX_HANDS - 1 do
    if fMinimap.HandShow[I] and not KMSamePoint(fMinimap.HandLocs[I], KMPOINT_ZERO) then
    begin
      T := MapCoordsToLocal(fMinimap.HandLocs[I].X, fMinimap.HandLocs[I].Y, fLocRad);
      TKMRenderUI.WriteText(T.X, T.Y - 6, 0, IntToStr(I+1), fntOutline, taCenter);
    end;
  end;

  if not Enabled then
    TKMRenderUI.WriteBevel(AbsLeft, AbsTop, Width+1, Height+1, 0, 0.5);
end;


end.

