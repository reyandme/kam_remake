unit KM_Sort;
{$ifdef fpc}{$mode delphi}{$H+}{$endif}
interface

type
  TKMCompFunc = function (const aElem1, aElem2): Integer;

procedure Sort(var aArr; aMinIdx,aMaxIdx,aSize: Integer; aCompFunc: TKMCompFunc);


implementation

{ Universal Quick sort procedure }
// It is possible to sort array of standard data types and also array of records
// Compare function must be defined
procedure Sort(var aArr; aMinIdx,aMaxIdx,aSize: Integer; aCompFunc: TKMCompFunc);
type
  TWByteArray = array[Word] of Byte;
  PWByteArray = ^TWByteArray;

  procedure QuickSort(MinIdx,MaxIdx: Integer; var SwapBuf);
  var
    lS,hS,pivotS: Integer;
    pArr: PWByteArray;
  begin
    pArr := @aArr;
    lS := MinIdx;
    hS := MaxIdx;
    pivotS := ((hS+lS) div (2*aSize)) * aSize;
    repeat
      while (aCompFunc( pArr[lS], pArr[pivotS] ) < 0) do Inc(lS, aSize);
      while (aCompFunc( pArr[hS], pArr[pivotS] ) > 0) do Dec(hS, aSize);
      if (lS <= hS) then
      begin
        if (lS < hS) then
        begin
          Move(pArr[lS], SwapBuf, aSize);
          Move(pArr[hS], pArr[lS], aSize);
          Move(SwapBuf, pArr[hS], aSize);
          // Position of pivot was changed
          if (lS = pivotS) then
            pivotS := hS
          else if (hS = pivotS) then
            pivotS := lS;
        end;
        Inc(lS, aSize);
        Dec(hS, aSize);
      end;
    until (lS > hS);
    if (MinIdx < hS) then
      QuickSort(MinIdx,hS,SwapBuf);
    if (MaxIdx > lS) then
      QuickSort(lS,MaxIdx,SwapBuf);
  end;

var
  Buf: array of Byte;
begin
  if (aMinIdx >= aMaxIdx) OR (aSize = 0) then
    Exit;
  SetLength(Buf, aSize);
  QuickSort(aMinIdx*aSize,aMaxIdx*aSize,Buf[0]);
end;

end.
