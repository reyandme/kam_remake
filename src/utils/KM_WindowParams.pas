unit KM_WindowParams;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF FPC}Forms,{$ENDIF}   //Lazarus do not know UITypes
  {$IFDEF WDC}UITypes,{$ENDIF} //We use settings in console modules
  KM_Points;

type
  TKMWindowParamsRecord = record
    Width, Height, Left, Top: SmallInt;
    State: TWindowState;
  end;

  TKMWindowParams = class
  private
    fWidth, fHeight, fLeft, fTop: SmallInt; // Window size/position on the screen
    fState: TWindowState;                   // Window state (wsNormal/wsMaximized)
    fLockParams: Boolean;                   // Lock updating window params, used when Fullscreen turned On
    fIsChanged: Boolean;
    fNeedResetToDefaults: Boolean;          // Flag, when set params should be updated with defaults
  public
    constructor Create;
    property Width: SmallInt read fWidth write fWidth;
    property Height: SmallInt read fHeight write fHeight;
    property Left: SmallInt read fLeft write fLeft;
    property Top: SmallInt read fTop write fTop;
    property State: TWindowState read fState write fState;
    property IsChanged: Boolean read fIsChanged;
    property NeedResetToDefaults: Boolean read fNeedResetToDefaults write fNeedResetToDefaults;

    procedure ApplyWindowParams(const aParams: TKMWindowParamsRecord; aDefaults: Boolean = False);
    procedure LockParams;
    procedure UnlockParams;
    function IsValid(aMonitorsInfo: TKMPointArray): Boolean;
  end;

implementation
uses
  Math,
  KM_Defaults;


{ TKMWindowParams }
constructor TKMWindowParams.Create;
begin
  inherited;
  fIsChanged := False;
  fLockParams := False;
  fNeedResetToDefaults := False;
end;


procedure TKMWindowParams.ApplyWindowParams(const aParams: TKMWindowParamsRecord; aDefaults: Boolean = False);
begin
  if not fLockParams then
  begin
    fWidth := aParams.Width;
    fHeight := aParams.Height;
    fLeft := aParams.Left;
    fTop := aParams.Top;
    fState := aParams.State;
    fIsChanged := True;
    fNeedResetToDefaults := aDefaults;
  end;
end;


procedure TKMWindowParams.LockParams;
begin
  fLockParams := True;
end;


procedure TKMWindowParams.UnlockParams;
begin
  fLockParams := False;
end;


// Check window param, with current Screen object
function TKMWindowParams.IsValid(aMonitorsInfo: TKMPointArray): Boolean;
var
  I, ScreenMaxWidth, ScreenMaxHeight: Integer;
begin
  ScreenMaxWidth := 0;
  ScreenMaxHeight := 0;
  // Calc Max width/height for multi screen systems
  // Assume appending monitor screens left to right, so summarise width, get max of height
  for I := Low(aMonitorsInfo) to High(aMonitorsInfo) do
  begin
    ScreenMaxWidth := ScreenMaxWidth + aMonitorsInfo[I].X;
    ScreenMaxHeight := Max(ScreenMaxHeight, aMonitorsInfo[I].Y);
  end;
  // Do not let put window too much left or right. 100px is enough to get it back in that case
  Result := (fWidth >= MIN_RESOLUTION_WIDTH)
        and (fWidth <= ScreenMaxWidth)
        and (fHeight >= MIN_RESOLUTION_HEIGHT)
        and (fHeight <= ScreenMaxHeight)
        and (fState in [TWindowState.wsNormal, TWindowState.wsMaximized]);
end;


end.
