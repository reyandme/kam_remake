unit KM_WindowParams;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF WDC}UITypes,{$ENDIF} //We use settings in console modules
  Forms,
  KM_Points;

type
  TKMWindowParamsRecord = record
    Width, Height, Left, Top: SmallInt;
    State: TWindowState;
    Position: TPosition;
  end;

  TKMWindowParams = class
  private
    fWidth, fHeight, fLeft, fTop: SmallInt; // Window size/position on the screen
    fState: TWindowState;                   // Window state (wsNormal/wsMaximized)
    fPosition: TPosition;                   // Window position (poDesigned/poCenterScreen)
    fFixedPosition: Boolean;                // Set if user can fix position style in case other styles do not work properly
                                            // There was bugreport when game window appeared only with poCenterScreen position on Linux
    fLockParams: Boolean;                   // Lock updating window params, used when Fullscreen turned On
    fIsChanged: Boolean;
    fNeedResetToDefaults: Boolean;
    procedure SetHeight(const aValue: SmallInt);
    procedure SetWidth(const aValue: SmallInt);          // Flag, when set params should be updated with defaults
  public
    constructor Create;
    property Width: SmallInt read fWidth write SetWidth;
    property Height: SmallInt read fHeight write SetHeight;
    property Left: SmallInt read fLeft write fLeft;
    property Top: SmallInt read fTop write fTop;
    property State: TWindowState read fState write fState;
    property Position: TPosition read fPosition write fPosition;
    property FixedPosition: Boolean read fFixedPosition write fFixedPosition;
    property IsChanged: Boolean read fIsChanged;
    property NeedResetToDefaults: Boolean read fNeedResetToDefaults write fNeedResetToDefaults;

    procedure ApplyWindowParams(const aParams: TKMWindowParamsRecord; aDefaults: Boolean = False);
    procedure LockParams;
    procedure UnlockParams;
    function IsValid(aMonitorsInfo: TKMPointArray): Boolean;

    function ObjToString: String;
  end;

implementation
uses
  Math, SysUtils, TypInfo,
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
    Width := aParams.Width; // Use property to use setter for value validation
    Height := aParams.Height; // Use property to use setter for value validation
    fLeft := aParams.Left;
    fTop := aParams.Top;
    fState := aParams.State;
    // Do not apply Position property if FixedPosition is set
    if not fFixedPosition then    
      fPosition := aParams.Position;
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
const
  WINDOW_AT_EDGE_GAP = 100; // in px, how close could be window near the screen edge (left or top)
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
  Result := (fWidth >= RESOLUTION_WIDTH_MIN)
        and (fWidth <= ScreenMaxWidth)
        and (fLeft  <= ScreenMaxWidth - WINDOW_AT_EDGE_GAP)
        and (fHeight >= RESOLUTION_HEIGHT_MIN)
        and (fHeight <= ScreenMaxHeight)
        and (fTop    <= ScreenMaxHeight - WINDOW_AT_EDGE_GAP)
        and (fState in [TWindowState.wsNormal, TWindowState.wsMaximized]);
        // it seems there is no need to test Position property
end;


function TKMWindowParams.ObjToString: String;
begin
  Result := Format('Left = %d Top = %d Width = %d Height = %d State = %s Position = %s FixedPosition = %s',
                   [fLeft, fTop, fWidth, fHeight,
                    GetEnumName(TypeInfo(TWindowState), Integer(fState)),
                    GetEnumName(TypeInfo(TPosition), Integer(fPosition)),
                    BoolToStr(fFixedPosition, True)]);
end;


procedure TKMWindowParams.SetHeight(const aValue: SmallInt);
begin
  fHeight := Max(aValue, RESOLUTION_HEIGHT_MIN);
end;


procedure TKMWindowParams.SetWidth(const aValue: SmallInt);
begin
  fWidth := Max(aValue, RESOLUTION_WIDTH_MIN);
end;


end.
