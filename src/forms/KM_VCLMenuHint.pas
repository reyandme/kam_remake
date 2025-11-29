unit KM_VclMenuHint;
interface
uses
  Classes,
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Controls, Menus, ExtCtrls, Forms;

type
  // This type allow to show hints over menu items
  TKMVclMenuItemHint = class(THintWindow)
  private
    activeMenuItem: TMenuItem;
    showTimer: TTimer;
    hideTimer: TTimer;
    procedure HideTime(Sender: TObject);
    procedure ShowTime(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure DoActivateHint(menuItem: TMenuItem);
    destructor Destroy; override;
  end;

implementation


{ TKMVclMenuItemHint }
constructor TKMVclMenuItemHint.Create(AOwner: TComponent);
begin
  inherited;

  showTimer := TTimer.Create(Self);
  showTimer.Interval := Application.HintPause;

  hideTimer := TTimer.Create(Self);
  hideTimer.Interval := Application.HintHidePause;
end;


destructor TKMVclMenuItemHint.Destroy;
begin
  hideTimer.OnTimer := nil;
  showTimer.OnTimer := nil;
  Self.ReleaseHandle;

  showTimer.Free;
  hideTimer.Free;

  inherited;
end;


procedure TKMVclMenuItemHint.DoActivateHint(menuItem: TMenuItem);
begin
  // Speedup removing of an old hint window
  HideTime(Self);

  if (menuItem = nil) or (menuItem.Hint = '') then
  begin
    activeMenuItem := nil;
    Exit;
  end;

  activeMenuItem := menuItem;

  showTimer.OnTimer := ShowTime;
  hideTimer.OnTimer := HideTime;
end;


procedure TKMVclMenuItemHint.HideTime(Sender: TObject);
begin
  // Hide hint window
  ReleaseHandle;
  hideTimer.OnTimer := nil;
end;


procedure TKMVclMenuItemHint.ShowTime(Sender: TObject);
var
  r: TRect;
  wdth: integer;
  hght: integer;
begin
  if activeMenuItem <> nil then
  begin
    // Size and position
    wdth := Canvas.TextWidth(activeMenuItem.Hint);
    hght := Canvas.TextHeight(activeMenuItem.Hint);

    r.Left := Mouse.CursorPos.X + 16;
    r.Top := Mouse.CursorPos.Y + 16;
    r.Right := r.Left + wdth + 6;
    r.Bottom := r.Top + hght + 4;

    ActivateHint(r, activeMenuItem.Hint);
  end;
  showTimer.OnTimer:= nil;  
end;


end.