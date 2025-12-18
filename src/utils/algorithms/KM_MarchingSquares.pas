unit KM_MarchingSquares;
{$I KaM_Remake.inc}
interface
uses
  KM_Points, KM_CommonClasses, Generics.Collections;

type
  IKMData2D<T> = interface(IInterface)
    ['{07066900-CC25-4134-9330-D58BEAE04D5B}']
    function GetData(X, Y: Integer): T;
  end;

  TKMMarchingSquares = class
  private
    fWidth: Integer;
    fHeight: Integer;
    fData: IKMData2D<Boolean>;

    // Data that was countered once
    // We suggest all tiles around perimeter vertex as countered
    fCountouredData: TDictionary<Integer, Boolean>;

    function GetSurroundingsValue(X, Y: Integer): Integer;
    function GetSurroundingsValueAndMark(X, Y: Integer; aMark: Boolean = True): Integer;
    function GetPlainIndex(X, Y: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetData(aData: IKMData2D<Boolean>; aWidth, aHeight: Integer);

    function IdentifyPerimeters(out aPerimeters: TList<TKMPointList>): Boolean;
    function IdentifyFirstPerimeter(out aPerimeterVertexes: TKMPointList): Boolean;
    function IdentifyPerimeter(out aPerimeterVertexes: TKMPointList; const aInitialX, aInitialY: Integer): Boolean;
  end;

  //todo -cComplicated: There is a known bug, when area has single cells, connected diagonally, then half of them will be not bordered
  //
  //   Before        After      Expected
  //         X             X          |X|
  //       X            |X|         |X|
  //     X     ->      X          |X|
  //   X            |X|         |X|
  //


const
  POINT_ADJ: array[TKMDirection4] of TKMPoint = (
    (X:  0; Y:  0), //drNA
    (X:  0; Y: -1), //drN
    (X:  1; Y:  0), //drE
    (X:  0; Y:  1), //drS
    (X: -1; Y:  0)  //drW
  );

implementation
uses
  Math, KM_DevPerfLog, KM_DevPerfLogTypes;


{ TKMMarchingSquares }
constructor TKMMarchingSquares.Create;
begin
  inherited Create;

  fCountouredData := TDictionary<Integer, Boolean>.Create;
end;


destructor TKMMarchingSquares.Destroy;
begin
  fCountouredData.Free;

  inherited;
end;


procedure TKMMarchingSquares.SetData(aData: IKMData2D<Boolean>; aWidth, aHeight: Integer);
begin
  fData := aData;
  fWidth := aWidth;
  fHeight := aHeight;
end;


function TKMMarchingSquares.GetPlainIndex(X, Y: Integer): Integer;
begin
  Result := Y*fWidth + X;
end;


// Identify all countours
function TKMMarchingSquares.IdentifyPerimeters(out aPerimeters: TList<TKMPointList>): Boolean;
var
  I, K, countoursCnt: Integer;

  perimeter: TKMPointList;
begin
  Assert(fWidth*fHeight > 0, 'TKMMarchingSquares was not initialized');

  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psMarchingSquares);
  {$ENDIF}

  try
    countoursCnt := 0;
    fCountouredData.Clear;
    aPerimeters.Clear;
    for I := 0 to fHeight - 1 do
      for K := 0 to fWidth - 1 do
        if fData.GetData(K, I) and not fCountouredData.ContainsKey(GetPlainIndex(K, I)) then
        begin
          perimeter := TKMPointList.Create;
          if IdentifyPerimeter(perimeter, K, I) then
          begin
            aPerimeters.Add(perimeter);
            Inc(countoursCnt);
          end
          else
            perimeter.Free;
        end;
    Result := (countoursCnt > 0);
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psMarchingSquares);
    {$ENDIF}
  end;
end;


// Identify only the very first perimeter
function TKMMarchingSquares.IdentifyFirstPerimeter(out aPerimeterVertexes: TKMPointList): Boolean;
var
  I, K: Integer;
begin
  Assert(fWidth*fHeight > 0, 'TKMMarchingSquares was not initialized');

  Result := False;
  for I := 0 to fHeight - 1 do
    for K := 0 to fWidth - 1 do
      if fData.GetData(K, I)
      and not fCountouredData.ContainsKey(GetPlainIndex(K, I)) then //Don't make contour twice
        Exit(IdentifyPerimeter(aPerimeterVertexes, K, I));
end;


// Identify one perimeter from given initial point
function TKMMarchingSquares.IdentifyPerimeter(out aPerimeterVertexes: TKMPointList; const aInitialX, aInitialY: Integer): Boolean;
var
  x, y, initialX, initialY, initialValue: Integer;
  direction, prevDir: TKMDirection4;
begin
  Assert(fWidth*fHeight > 0, 'TKMMarchingSquares was not initialized');

  Result := False;

  initialX := EnsureRange(aInitialX, 0, fWidth);
  initialY := EnsureRange(aInitialY, 0, fHeight);

  initialValue := GetSurroundingsValue(initialX, initialY); // Do not mark tiles

  // Check if supplied initial coordinates lie on a perimeter
  if (initialValue = 0) or (initialValue = 15) then
    Exit;

  x := initialX;
  y := initialY;
  prevDir := drNA;

  aPerimeterVertexes.Add(TKMPoint.New(x, y));

  repeat
    case GetSurroundingsValueAndMark(x, y) of
      1:  direction := drN;
      2:  direction := drE;
      3:  direction := drE;
      4:  direction := drW;
      5:  direction := drN;
      6:  if prevDir = drN then
            direction := drW
          else
            direction := drE;
      7:  direction := drE;
      8:  direction := drS;
      9:  if prevDir = drE then
            direction := drN
          else
            direction := drS;
      10: direction := drS;
      11: direction := drS;
      12: direction := drW;
      13: direction := drN;
      14: direction := drW;
    else
      Exit;
    end;

    x := x + POINT_ADJ[direction].X;
    y := y + POINT_ADJ[direction].Y; // accomodate change of basis
    prevDir := direction;
    aPerimeterVertexes.Add(TKMPoint.New(x, y))
  until (x = initialX) and (y = initialY);

  Result := True;
end;


function TKMMarchingSquares.GetSurroundingsValue(X, Y: Integer): Integer;
begin
  Result := GetSurroundingsValueAndMark(X, Y, False);
end;


function TKMMarchingSquares.GetSurroundingsValueAndMark(X, Y: Integer; aMark: Boolean = True): Integer;
var
  index: Integer;
begin
  Result := 0;
  if fData.GetData(X - 1, Y - 1) then
  begin
    Result := Result or 1;
    if aMark then
    begin
      index := GetPlainIndex(X - 1, Y - 1);
      if not fCountouredData.ContainsKey(index) then
        fCountouredData.Add(index, True);
    end;
  end;

  if fData.GetData(X, Y - 1) then
  begin
    Result := Result or 2;
    if aMark then
    begin
      index := GetPlainIndex(X, Y - 1);
      if not fCountouredData.ContainsKey(index) then
        fCountouredData.Add(index, True);
    end;
  end;

  if fData.GetData(X - 1, Y) then
  begin
    Result := Result or 4;
    if aMark then
    begin
      index := GetPlainIndex(X - 1, Y);
      if not fCountouredData.ContainsKey(index) then
        fCountouredData.Add(index, True);
    end;
  end;

  if fData.GetData(X, Y) then
  begin
    Result := Result or 8;
    if aMark then
    begin
      index := GetPlainIndex(X, Y);
      if not fCountouredData.ContainsKey(index) then
        fCountouredData.Add(index, True);
    end;
  end;
end;


end.

