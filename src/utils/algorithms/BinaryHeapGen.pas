// From https://github.com/qiao/heap.js
//Ported by Krom for project Castlesand
unit BinaryHeapGen;
{$I KaM_Remake.inc}
interface
uses Generics.Collections;


type
  TComparator<T: class> = function(A, B: T) : Boolean of object;


  TObjectBinaryHeap<T: class> = class
  private
    fCount: Integer;
    fItems: array of T;
    fCmp: TComparator<T>;
    procedure _siftdown(startpos, pos: Integer);
    procedure _siftup(pos: Integer);
  public
    constructor Create(aSize: Cardinal; aCmp: TComparator<T>);
    destructor Destroy; override;

    property Count: Integer read fCount;

    procedure EnlargeTo(aSize: Cardinal);
    procedure Clear;
    function IsEmpty: Boolean;
    function Pop: T;
    procedure Push(aItem: T);
    procedure UpdateItem(x: T);
  end;


implementation
uses
  SysUtils;

const
  GROW_FACTOR = 1.618; // golden ratio


{ TBinaryHeap }
constructor TObjectBinaryHeap<T>.Create(aSize: Cardinal; aCmp: TComparator<T>);
begin
  inherited Create;

  fCmp := aCmp;

  SetLength(fItems, aSize);
end;


destructor TObjectBinaryHeap<T>.Destroy;
begin
  Clear;

  inherited;
end;


procedure TObjectBinaryHeap<T>.EnlargeTo(aSize: Cardinal);
begin
  if aSize > Length(fItems) then
    SetLength(fItems, aSize);
end;


procedure TObjectBinaryHeap<T>.Clear;
var
  I: Integer;
begin
  for I := fCount - 1 downto 0 do
    FreeAndNil(fItems[I]);

  fCount := 0;
end;


function TObjectBinaryHeap<T>.IsEmpty: Boolean;

begin
  Result := (fCount = 0);
end;


//Push item onto heap, maintaining the heap invariant.
procedure TObjectBinaryHeap<T>.Push(aItem: T);
begin
  if Length(fItems) <= fCount then
    SetLength(fItems, Round(fCount * GROW_FACTOR));

  fItems[fCount] := aItem;
  Inc(fCount);

  _siftdown(0, fCount - 1);
end;


//Pop the smallest item off the heap, maintaining the heap invariant.
function TObjectBinaryHeap<T>.Pop: T;
var
  lastelt, returnitem: T;
begin
  if fCount = 0 then Exit(nil);

  lastelt := fItems[fCount - 1];
  Dec(fCount);

  if (fCount <> 0) then
  begin
    returnitem := fItems[0];
    fItems[0] := lastelt;
    _siftup(0);
  end
  else
  begin
    returnitem := lastelt;
  end;

  Result := returnitem;
end;


//Update the position of the given item in the heap.
//This function should be called every time the item is being modified.
procedure TObjectBinaryHeap<T>.UpdateItem(x: T);
var
  I: Integer;
begin
  for I := 0 to fCount - 1 do
  if fItems[I] = x then
    Break;

  _siftdown(0, I);
  _siftup(I);
end;


procedure TObjectBinaryHeap<T>._siftdown(startpos, pos: Integer);
var
  newitem, parent: T;
  parentpos: Integer;
begin
    newitem := fItems[pos];
    while (pos > startpos) do
    begin
      parentpos := (pos - 1) shr 1;
      parent := fItems[parentpos];
      if fCmp(newitem, parent) then
      begin
        fItems[pos] := parent;
        pos := parentpos;
        Continue;
      end;
      Break;
    end;
  fItems[pos] := newitem;
end;


procedure TObjectBinaryHeap<T>._siftup(pos: Integer);
var
  childpos, endpos, rightpos, startpos: Integer;
  newitem: T;
begin
    endpos := fCount;
    startpos := pos;
    newitem := fItems[pos];
    childpos := 2 * pos + 1;
    while (childpos < endpos) do
    begin
      rightpos := childpos + 1;
      if (rightpos < endpos) and (not fCmp(fItems[childpos], fItems[rightpos])) then
      begin
        childpos := rightpos;
      end;
      fItems[pos] := fItems[childpos];
      pos := childpos;
      childpos := 2 * pos + 1;
    end;
    fItems[pos] := newitem;
    _siftdown(startpos, pos);
end;


end.

