unit KM_Viewport;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWINDOWS} Windows, {$ENDIF}
  KM_CommonClasses, KM_CommonTypes, KM_Points
  {$IFDEF Unix}
  , Mouse
  {$ENDIF}
  {$IFDEF FPC}
  {$IFDEF Unix}
  , Types
  {$ENDIF}
  {$ENDIF}
  ;


type
  TKMViewport = class
  private
    fMapX, fMapY: Word;
    fTopHill: Single;
    fPosition: TKMPointF;
    fScrolling: Boolean;
    fScrollStarted: Cardinal;
    fViewportClip: TPoint;
    fViewRect: TKMRect;
    fZoom: Single;
    fPanTo, fPanFrom: TKMPointF;
    fPanImmediately : Boolean;
    fPanDuration, fPanProgress: Cardinal;
    fToolbarWidth: Integer;

    fOnPositionSet: TPointFEvent;

    function GetPosition: TKMPointF;
    procedure SetPosition(const Value: TKMPointF);
    procedure SetZoom(aZoom: Single);
    function GetToolbarWidth: Integer;
    function GetTopPad: Single;
    function GetZoomedCellSizePx: Single; inline;

    property ToolbarWidth: Integer read GetToolbarWidth;
    property ZoomedCellSizePX: Single read GetZoomedCellSizePx; // Cell size in pixels in current zoom
  public
    ScrollKeyLeft, ScrollKeyRight, ScrollKeyUp, ScrollKeyDown, ZoomKeyIn, ZoomKeyOut: boolean;
    constructor Create(aToolBarWidth: Integer; aWidth, aHeight: Integer; aOnPositionSet: TPointFEvent);

    property Position: TKMPointF read GetPosition write SetPosition;
    property Scrolling: Boolean read fScrolling;
    property ViewportClip: TPoint read fViewportClip;
    property ViewRect: TKMRect read fViewRect;
    property Zoom: Single read fZoom write SetZoom;

    property TopPad: Single read GetTopPad;

    procedure ResetZoom;
    procedure Resize(NewWidth, NewHeight: Integer);
    procedure ResizeMap(aMapX, aMapY: Word; aTopHill: Single);
    function GetClip: TKMRect; //returns visible area dimensions in map space
    function GetMinimapClip: TKMRect;
    function GetMinimapClipLines: TKMDirection4Set;
    procedure ReleaseScrollKeys;
    procedure GameSpeedChanged(aFromSpeed, aToSpeed: Single);
    function MapToScreen(const aMapLoc: TKMPointF): TKMPoint;
    procedure PanTo(const aLoc: TKMPointF; aTicksCnt: Cardinal);
    procedure CinematicReset;

    procedure TopHillChanged(aValue: Single);

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    procedure UpdateStateIdle(aFrameTime: Cardinal; aAllowMouseScrolling: Boolean; aInCinematic: Boolean);
    function ToStr: string;

    procedure Paint;
  end;


implementation
uses
  Math, SysUtils,
  KromUtils, KM_InterfaceTypes,
  KM_Resource, KM_ResTypes,
  KM_RenderAux,
  KM_Main, KM_System, KM_GameApp, KM_GameSettings,
  KM_Defaults, KM_CommonUtils;


{ TKMViewport }
constructor TKMViewport.Create(aToolBarWidth: Integer; aWidth, aHeight: Integer; aOnPositionSet: TPointFEvent);
begin
  inherited Create;

  fToolbarWidth := aToolBarWidth;
  fOnPositionSet := aOnPositionSet;

  fMapX := 2; //Avoid division by 0
  fMapY := 2; //Avoid division by 0

  CinematicReset;

  fZoom := 1;
  ReleaseScrollKeys;

  if Assigned(fOnPositionSet) then
    fOnPositionSet(fPosition);

  Resize(aWidth, aHeight);
end;


procedure TKMViewport.SetZoom(aZoom: Single);
var
  sizeY, mapZoom: Single;
const
  BORDER_MARGIN = 1.1; // How much we can zoom-out for zbLoose ZoomBehaviour
begin
  fZoom := EnsureRange(aZoom, 0.01, 8);

  sizeY := fMapY + TopPad;

  case (gGameSettings.ZoomBehaviour) of
    // Limit the zoom to within the map boundaries
    zbRestricted:
      begin
        mapZoom := Max(fViewportClip.X/(CELL_SIZE_PX * (fMapX - 1)), fViewportClip.Y/(CELL_SIZE_PX * (sizeY - 1))); // -1 to not show last column/row under FOW (out of the map)
        fZoom := Max(fZoom, mapZoom);
      end;
    // Prevents the zoom from crossing both map boundaries
    zbFull:
      begin
        mapZoom := Min(fViewportClip.X/(CELL_SIZE_PX * (fMapX - 1)), fViewportClip.Y/(CELL_SIZE_PX * (sizeY - 1)));
        fZoom := Max(fZoom, mapZoom);
      end;
    // Limit the zoom to 1.1x the map width or height
    zbLoose:
      begin
        mapZoom := Min(fViewportClip.X/(CELL_SIZE_PX * (fMapX - 1)), fViewportClip.Y/(CELL_SIZE_PX * (sizeY - 1))) / BORDER_MARGIN;
        mapZoom := Min(mapZoom, 1);
        fZoom := Max(fZoom, mapZoom);
      end;
  end;

  SetPosition(fPosition); //To ensure it sets the limits smoothly
end;


procedure TKMViewport.ResetZoom;
begin
  Zoom := gGameSettings.DefaultZoom;
end;


procedure TKMViewport.Resize(NewWidth, NewHeight: Integer);
begin
  fViewRect.Left   := ToolbarWidth;
  fViewRect.Top    := 0;
  fViewRect.Right  := NewWidth;
  fViewRect.Bottom := NewHeight;

  fViewportClip.X := fViewRect.Right - fViewRect.Left;
  fViewportClip.Y := fViewRect.Bottom - fViewRect.Top;

  SetZoom(fZoom); //View size has changed and that affects Zoom restrictions
end;


procedure TKMViewport.ResizeMap(aMapX, aMapY: Word; aTopHill: Single);
begin
  fMapX := aMapX;
  fMapY := aMapY;
  fTopHill := aTopHill;
  SetPosition(fPosition); //EnsureRanges
end;


function TKMViewport.GetPosition: TKMPointF;
begin
  Result.X := EnsureRange(fPosition.X, 1, fMapX);
  Result.Y := EnsureRange(fPosition.Y, 1, fMapY);
end;


function TKMViewport.GetToolbarWidth: Integer;
begin
  // Don't render toolbar when SAVE_MAP_TO_FBO is set
  if SAVE_MAP_TO_FBO_RENDER then Exit(0);

  Result := fToolbarWidth;
end;


function TKMViewport.GetTopPad: Single;
begin
  Result := fTopHill + 0.75;  //Leave place on top for highest hills + 1 unit
end;


procedure TKMViewport.SetPosition(const Value: TKMPointF);
var
  tilesX, tilesY: Single;
begin

  case (gGameSettings.ZoomBehaviour) of
    zbRestricted :
      begin
        tilesX := fViewportClip.X/2/ZoomedCellSizePX;
        tilesY := fViewportClip.Y/2/ZoomedCellSizePX;

        // Set position as a pointF in the map coordinates, but also with possible TopPad at the top
        fPosition.X := EnsureRange(Value.X,
                                   tilesX,               // Min visible map coordinate is 0
                                   fMapX - 1 - tilesX ); // Max visible map coordinate is fMapX - 1
        //Top row should be visible
        fPosition.Y := EnsureRange(Value.Y,
                                   tilesY - TopPad,     // Min visible map coordinate is -TopPad
                                   fMapY - 1 - tilesY); // Max visible map coordinate is fMapY - 1
      end;
    zbFull :
      begin
        tilesX := min(fViewportClip.X/2/ZoomedCellSizePX, (fMapX - 1) / 2);
        tilesY := min(fViewportClip.Y/2/ZoomedCellSizePX, (fMapY - 1 + TopPad) / 2);

        // Set position as a pointF in the map coordinates, but also with possible TopPad at the top
        fPosition.X := EnsureRange(Value.X,
                                   tilesX,               // Min visible map coordinate is 0
                                   fMapX - 1 - tilesX ); // Max visible map coordinate is fMapX - 1
        //Top row should be visible
        fPosition.Y := EnsureRange(Value.Y,
                                   tilesY - TopPad,     // Min visible map coordinate is -TopPad
                                   fMapY - 1 - tilesY); // Max visible map coordinate is fMapY - 1
      end;
    zbLoose :
      begin
        // Set position as a pointF in the map coordinates, but also with possible TopPad at the top
        fPosition.X := EnsureRange(Value.X,
                                   0,               // Min visible map coordinate is 0
                                   fMapX - 1); // Max visible map coordinate is fMapX - 1
        //Top row should be visible
        fPosition.Y := EnsureRange(Value.Y,
                                   0,     // Min visible map coordinate is -TopPad
                                   fMapY - 1); // Max visible map coordinate is fMapY - 1
      end;
  end;

  if Assigned(fOnPositionSet) then
    fOnPositionSet(fPosition);
end;


function TKMViewport.GetZoomedCellSizePx: Single;
begin
  Result := CELL_SIZE_PX * fZoom;
end;


//Acquire boundaries of area visible to user (including mountain tops from the lower tiles)
//TestViewportClipInset is for debug, allows to see if everything gets clipped correct
function TKMViewport.GetClip: TKMRect;
begin
  Result.Left   := Math.Max(Round(fPosition.X
                         - (fViewportClip.X/2 - fViewRect.Left + ToolbarWidth) / ZoomedCellSizePX), 1);
  Result.Right  := Math.Min(Round(fPosition.X
                         + (fViewportClip.X/2 + fViewRect.Left - ToolbarWidth) / ZoomedCellSizePX) + 1, fMapX - 1);
  //Small render problem could be encountered at the top of clip rect
  //This small problem could be seen with reshade app (with displaydepth filter ON)
  //Enlarge clip viewport by 1 to fix it
  Result.Top    := Math.Max(Round(fPosition.Y
                         - fViewportClip.Y/2 / ZoomedCellSizePX) - 1, 1); // - 1 to update clip rect to the top on scroll
  Result.Bottom := Math.Min(Round(fPosition.Y
                         + fViewportClip.Y/2 / ZoomedCellSizePX) + 5, fMapY - 1); // + 5 for high trees

  if TEST_VIEW_CLIP_INSET then
    Result := KMRectGrow(Result, -5);
end;


//Same as above function but with some values changed to suit minimap
function TKMViewport.GetMinimapClip: TKMRect;
begin
  Result.Left   := Max(Round(fPosition.X - (fViewportClip.X/2 - fViewRect.Left + ToolbarWidth)/ZoomedCellSizePX) + 1, 1);
  Result.Right  := Min(Round(fPosition.X + (fViewportClip.X/2 + fViewRect.Left - ToolbarWidth)/ZoomedCellSizePX) + 1, fMapX);
  Result.Top    := Max(Round(fPosition.Y - fViewportClip.Y/2/ZoomedCellSizePX) + 1, 1);
  Result.Bottom := Min(Round(fPosition.Y + fViewportClip.Y/2/ZoomedCellSizePX) + 1, fMapY);
end;


//Acquires a bit array that holds what camera lines to draw on the minimap
function TKMViewport.GetMinimapClipLines: TKMDirection4Set;
begin
  if Round(fPosition.X - (fViewportClip.X/2 - fViewRect.Left + ToolbarWidth)/ZoomedCellSizePX) + 1 >= 1 then
    Include(Result, drW);
  if Round(fPosition.Y + TopPad - fViewportClip.Y/2/ZoomedCellSizePX) + 1 >= 1 then
    Include(Result, drN);
  if Round(fPosition.X + (fViewportClip.X/2 + fViewRect.Left - ToolbarWidth)/ZoomedCellSizePX) + 1 <= fMapX then
    Include(Result, drE);
  if Round(fPosition.Y + fViewportClip.Y/2/ZoomedCellSizePX) + 1 <= fMapY then
    Include(Result, drS);
end;


procedure TKMViewport.ReleaseScrollKeys;
begin
  ScrollKeyLeft  := False;
  ScrollKeyRight := False;
  ScrollKeyUp    := False;
  ScrollKeyDown  := False;
  ZoomKeyIn      := False;
  ZoomKeyOut     := False;
end;


procedure TKMViewport.GameSpeedChanged(aFromSpeed, aToSpeed: Single);
var
  koef: Single;
begin
  if (aFromSpeed > 0) and (fPanDuration > 0) and not fPanImmediately then
  begin
    //Update PanDuration and Progress due to new game speed
    koef := aFromSpeed / aToSpeed;
    fPanDuration := Round((fPanDuration - fPanProgress) * koef);
    fPanProgress := Round(fPanProgress * koef);
    Inc(fPanDuration, fPanProgress);
  end;
end;


function TKMViewport.MapToScreen(const aMapLoc: TKMPointF): TKMPoint;
begin
  Result.X := Round((aMapLoc.X - fPosition.X) * ZoomedCellSizePX + fViewRect.Right / 2 + ToolbarWidth / 2);
  Result.Y := Round((aMapLoc.Y - fPosition.Y) * ZoomedCellSizePX + fViewRect.Bottom / 2);
end;


procedure TKMViewport.PanTo(const aLoc: TKMPointF; aTicksCnt: Cardinal);
begin
  fPanTo := aLoc;
  fPanFrom := fPosition;
  fPanImmediately := aTicksCnt = 0;
  fPanProgress := 0;
  fPanDuration := Round(aTicksCnt * gGameApp.Game.TickDuration);
  //Panning will be skipped when duration is zero
  if fPanImmediately then
    SetPosition(aLoc);
end;


procedure TKMViewport.CinematicReset;
begin
  fPanFrom := KMPOINTF_INVALID_TILE;
  fPanTo := KMPOINTF_INVALID_TILE;
end;


//Here we must test each edge to see if we need to scroll in that direction
//We scroll at SCROLLSPEED per 100 ms. That constant is defined in KM_Defaults
procedure TKMViewport.UpdateStateIdle(aFrameTime: Cardinal; aAllowMouseScrolling: Boolean; aInCinematic: Boolean);
const
  SCROLL_ACCEL_TIME = 400; // Time in ms that scrolling will be affected by acceleration
  SCROLL_FLEX = 4;         // Number of pixels either side of the edge of the screen which will count as scrolling
  DIRECTIONS_BITFIELD: array [0..15] of TKMCursorImageType = (
    kmcDefault, kmcScroll6, kmcScroll0, kmcScroll7,
    kmcScroll2, kmcDefault, kmcScroll1, kmcDefault,
    kmcScroll4, kmcScroll5, kmcDefault, kmcDefault,
    kmcScroll3, kmcDefault, kmcDefault, kmcDefault);

  function PanPointsAreValid: Boolean;
  begin
    Result := (fPanFrom <> KMPOINTF_INVALID_TILE)
          and (fPanTo   <> KMPOINTF_INVALID_TILE);
  end;

var
  I: Byte;
  timeSinceStarted: Cardinal;
  scrollAdv, zoomAdv: Single;
  cursorPoint: TKMPoint;
  screenBounds: TRect;
  mousePos: TPoint;
begin
  //Cinematics do not allow normal scrolling. The camera will be set and panned with script commands
  if aInCinematic then
  begin
    if not fPanImmediately and PanPointsAreValid then //Do not move viewport if pan points are not valid
    begin
      Inc(fPanProgress, aFrameTime);
      if fPanProgress >= fPanDuration then
      begin
        SetPosition(fPanTo); //Pan ended
        fPanImmediately := True; //Not panning
        fPanDuration := 0;
      end
      else
        SetPosition(KMLerp(fPanFrom, fPanTo, fPanProgress / fPanDuration));
    end;
    Exit;
  end;

  {$IFDEF MSWindows}
    //Don't use Mouse.CursorPos, it will throw an EOSError (code 5: access denied) in some cases when
    //the OS doesn't want us controling the mouse, or possibly when the mouse is reset in some way.
    //It happens for me in Windows 7 every time I press CTRL+ALT+DEL with the game running.
    //On Windows XP I get "call to an OS function failed" instead.
    if not Windows.GetCursorPos(mousePos) then Exit;
  {$ENDIF}
  {$IFDEF Unix}
    MousePos.X := GetMouseX;
    MousePos.Y := GetMouseY;
  {$ENDIF}
  if not gMain.GetScreenBounds(screenBounds) then Exit;

  //With multiple monitors the cursor position can be outside of this screen, which makes scrolling too fast
  cursorPoint.X := EnsureRange(mousePos.X, screenBounds.Left, screenBounds.Right );
  cursorPoint.Y := EnsureRange(mousePos.Y, screenBounds.Top , screenBounds.Bottom);

  //Do not do scrolling when the form is not focused (player has switched to another application)
  if not aAllowMouseScrolling or
     not gMain.IsFormActive or
    (not ScrollKeyLeft  and
     not ScrollKeyUp    and
     not ScrollKeyRight and
     not ScrollKeyDown  and
     not ZoomKeyIn      and
     not ZoomKeyOut     and
     not (cursorPoint.X <= screenBounds.Left + SCROLL_FLEX) and
     not (cursorPoint.Y <= screenBounds.Top + SCROLL_FLEX) and
     not (cursorPoint.X >= screenBounds.Right -1-SCROLL_FLEX) and
     not (cursorPoint.Y >= screenBounds.Bottom-1-SCROLL_FLEX)) then
  begin
    //Stop the scrolling (e.g. if the form loses focus due to other application popping up)
    ReleaseScrollKeys;
    fScrolling := False;

    if (gSystem.Cursor in [kmcScroll0 .. kmcScroll7]) then
      gSystem.Cursor := kmcDefault;

    fScrollStarted := 0;
    Exit;
  end;

  // Both advancements have minimal value > 0
  // ScrollAdv depends on Zoom. Value was taken empirically
  scrollAdv := (0.5 + gGameSettings.ScrollSpeed / 5) * aFrameTime / 100 / Math.Power(fZoom, 0.8);

  zoomAdv := (0.2 + gGameSettings.ScrollSpeed / 20) * aFrameTime / 1000;

  if FEAT_SCROLL_ACCEL then
  begin
    if fScrollStarted = 0 then
      fScrollStarted := TimeGet;
    timeSinceStarted := TimeSince(fScrollStarted);
    if timeSinceStarted < SCROLL_ACCEL_TIME then
      scrollAdv := Mix(scrollAdv, 0, timeSinceStarted / SCROLL_ACCEL_TIME);
  end;

  I := 0; //That is our bitfield variable for directions, 0..12 range
  //    3 2 6  These are directions
  //    1 * 4  They are converted from bitfield to actual cursor constants, see Arr array
  //    9 8 12

  //Keys
  if ScrollKeyLeft  then fPosition.X := fPosition.X - scrollAdv;
  if ScrollKeyUp    then fPosition.Y := fPosition.Y - scrollAdv;
  if ScrollKeyRight then fPosition.X := fPosition.X + scrollAdv;
  if ScrollKeyDown  then fPosition.Y := fPosition.Y + scrollAdv;
  if ZoomKeyIn      then fZoom := fZoom * (1 + zoomAdv);
  if ZoomKeyOut     then fZoom := fZoom * (1 - zoomAdv);
  //Mouse
  if cursorPoint.X <= screenBounds.Left   + SCROLL_FLEX then begin inc(I,1); fPosition.X := fPosition.X - scrollAdv*(1+(screenBounds.Left   - cursorPoint.X)/SCROLL_FLEX); end;
  if cursorPoint.Y <= screenBounds.Top    + SCROLL_FLEX then begin inc(I,2); fPosition.Y := fPosition.Y - scrollAdv*(1+(screenBounds.Top    - cursorPoint.Y)/SCROLL_FLEX); end;
  if cursorPoint.X >= screenBounds.Right -1-SCROLL_FLEX then begin inc(I,4); fPosition.X := fPosition.X + scrollAdv*(1-(screenBounds.Right -1-cursorPoint.X)/SCROLL_FLEX); end;
  if cursorPoint.Y >= screenBounds.Bottom-1-SCROLL_FLEX then begin inc(I,8); fPosition.Y := fPosition.Y + scrollAdv*(1-(screenBounds.Bottom-1-cursorPoint.Y)/SCROLL_FLEX); end;

  //Now do actual the scrolling, if needed
  fScrolling := I <> 0;
  if fScrolling then
    gSystem.Cursor := DIRECTIONS_BITFIELD[I] //Sample cursor type from bitfield value
  else
    if (gSystem.Cursor in [kmcScroll0 .. kmcScroll7]) then
      gSystem.Cursor := kmcDefault;

  SetZoom(fZoom); //EnsureRanges
  SetPosition(fPosition); //EnsureRanges
end;


procedure TKMViewport.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('Viewport');
  SaveStream.Write(fMapX);
  SaveStream.Write(fMapY);
  SaveStream.Write(fPosition);
  //Zoom is reset to 1 by default
end;


procedure TKMViewport.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.CheckMarker('Viewport');
  //Load map dimensions then Position so it could be fit to map
  LoadStream.Read(fMapX);
  LoadStream.Read(fMapY);
  LoadStream.Read(fPosition);

  SetPosition(fPosition); //EnsureRanges
end;


procedure TKMViewport.TopHillChanged(aValue: Single);
begin
  fTopHill := aValue / CELL_SIZE_PX;
end;


procedure TKMViewport.Paint;
begin
  gRenderAux.CircleOnTerrain(fPosition.X, fPosition.Y, 0.5, icCyan, icRed);
end;


function TKMViewport.ToStr: string;
begin
  Result := Format('Pos = %s; Zoom = %s ViewClip = (%d; %d) ViewRect = %s', [
                   fPosition.ToString, FormatFloat('0.###', fZoom), fViewportClip.X, fViewportClip.Y, fViewRect.ToString]);
end;


end.
