unit KM_Cursor;
{$I KaM_Remake.inc}
interface
uses
  Classes, KM_Defaults, KM_Points, KM_ResTileset;


type
  TKMCursor = class
  private
    fMode: TKMCursorMode; //Modes used in game (building, unit, road, etc..)
    procedure SetMode(aMode: TKMCursorMode);
    procedure Reset;
  public
    Pixel: TKMPoint;      //Cursor position in screen-space
    Float: TKMPointF;     //Precise cursor position in map coords
    Cell: TKMPoint;       //Cursor position cell
    PrevCell: TKMPoint;   //Cursor previous position cell
    SState: TShiftState;  //Thats actually used to see if Left or Right mouse button is pressed

    Tag1: Word;           //Tag to know building type, unit type etc
//    Tag2: Word;           //Extra Tag
    DragOffset: TKMPoint; //used to adjust actual Cursor Cell
    ObjectUID: Integer;   //Object found below cursor

    // MapEd brushes page
    MapEdShape: TKMMapEdShape;
    MapEdSize: Byte;
    MapEdBrushMask: TKMTileMaskKind;
    MapEdUseMagicBrush: Boolean;
    MapEdRandomizeTiling: Boolean;
    MapEdOverrideCustomTiles: Boolean;
    MapEdBlendingLvl: Byte;
    MapEdUseTerrainObjects: Boolean;

    //Objects Brush
    MapEdCleanBrush,
    MapEdOverrideObjects: Boolean;
    MapEdObjectsType: array[0..9] of Boolean;
    MapEdForestAge: Integer;
    MapEdObjectsDensity: Integer;

    // MapEd elevations page
    MapEdSlope: Byte;
    MapEdSpeed: Byte;
    MapEdConstHeight: Byte;

    // MapEd other pages
    MapEdDir: Byte;

    constructor Create;
    property Mode: TKMCursorMode read fMode write SetMode;
  end;


var
  gCursor: TKMCursor;


implementation


{TKMGameCursor}
constructor TKMCursor.Create;
begin
  inherited;

  Reset;
end;


procedure TKMCursor.Reset;
begin
  DragOffset := KMPOINT_ZERO;
  MapEdUseMagicBrush := False;
  SState := [];
  if fMode = cmNone then  //Reset Tag1 also, when reset mode
  begin
    Tag1 := 0;
//    Tag2 := 0;
  end;
  // Actually we need reset all fields when changing mode,
  // but lets reset only DragOffset for now, need to do lots of tests for other fields
end;


procedure TKMCursor.SetMode(aMode: TKMCursorMode);
begin
  fMode := aMode;

  Reset;
end;


end.
