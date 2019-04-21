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
    li,hi,mi,ls,hs,ms: Integer;
    pArr: PWByteArray;
  begin
    pArr := @aArr;
    li := MinIdx;
    hi := MaxIdx;
    mi := (li+hi) div 2;
    ls := li*aSize;
    hs := hi*aSize;
    ms := mi*aSize;
    repeat
      while (aCompFunc( pArr[ls], pArr[ms] ) < 0) do
      begin
        Inc(ls, aSize);
        Inc(li);
      end;
      while (aCompFunc( pArr[ms], pArr[hs] ) < 0) do
      begin
        Dec(hs, aSize);
        Dec(hi);
      end;
      if (ls <= hs) then
      begin
        Move(pArr[ls], SwapBuf, aSize);
        Move(pArr[hs], pArr[ls], aSize);
        Move(SwapBuf, pArr[hs], aSize);
        Inc(ls, aSize);
        Inc(li);
        Dec(hs, aSize);
        Dec(hi);
      end;
    until (ls > hs);
    if (MinIdx < hi) then
      QuickSort(MinIdx,hi,SwapBuf);
    if (li < MaxIdx) then
      QuickSort(li,MaxIdx,SwapBuf);
  end;
var
  Buf: array of Byte;
begin
  SetLength(Buf, aSize);
  QuickSort(aMinIdx,aMaxIdx,Buf[0]);
end;

end.
