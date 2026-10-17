unit KM_ResCursors;
{$I KaM_Remake.inc}
interface
uses
  Math, SysUtils, Classes,
  KM_Points, KM_ResTypes;

type
  TKMResCursors = class
  private
    fRXData: PRXData; // Store pointer to record instead of duplicating it
  public
    procedure SetRXDataPointer(aRXData: PRXData);

    function CursorOffset(aDir: TKMDirection): TKMPoint;
    function CursorTexID(aDir: TKMDirection): Integer;
  end;


implementation
uses
  KM_Defaults;

const
  // Which cursor is used for which direction
  DIRECTION_CURSOR: array [TKMDirection] of TKMCursorImageType = (
    kmcDirNA, kmcDir0, kmcDir1, kmcDir2, kmcDir3, kmcDir4, kmcDir5, kmcDir6, kmcDir7);

{ TKMResCursors }
procedure TKMResCursors.SetRXDataPointer(aRXData: PRXData);
begin
  fRXData := aRXData;
end;


// Return cursor offset for given direction, which is a signed(!) value
function TKMResCursors.CursorOffset(aDir: TKMDirection): TKMPoint;
begin
  // Screen pixels -> logical (HD-scaled) pivot
  Result.X := Round(fRXData.PivotXf(CURSOR_SPRITE_INDEX[DIRECTION_CURSOR[aDir]]));
  Result.Y := Round(fRXData.PivotYf(CURSOR_SPRITE_INDEX[DIRECTION_CURSOR[aDir]]));
end;


// Sprite index of the cursor
function TKMResCursors.CursorTexID(aDir: TKMDirection): Integer;
begin
  Result := CURSOR_SPRITE_INDEX[DIRECTION_CURSOR[aDir]];
end;


end.
