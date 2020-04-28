unit KM_CommonClasses;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, KM_Points, KM_CommonTypes, KM_WorkerThread;


type
  TKMSaveStreamFormat = (ssfBinary, ssfText);

  TKMemoryStream = class(TMemoryStream)
  public
    // Assert savegame sections
    procedure CheckMarker(const aTitle: string); virtual; abstract;
    procedure PlaceMarker(const aTitle: string); virtual; abstract;

    procedure ReadANSI(out aValue: string); virtual; abstract;
    procedure WriteANSI(const aValue: string); virtual; abstract;

    //Ansistrings saved by PascalScript into savegame
    procedure ReadHugeString(out Value: AnsiString); overload;
    procedure WriteHugeString(const Value: AnsiString); overload;

//    {$IFDEF DESKTOP}
    //Legacy format for campaigns info, maxlength 65k ansichars
    procedure ReadA(out Value: AnsiString); reintroduce; overload; virtual; abstract;
    procedure WriteA(const Value: AnsiString); reintroduce; overload; virtual; abstract;
//    {$ENDIF}
//    {$IFDEF TABLET}
//    //Legacy format for campaigns info, maxlength 65k ansichars
//    procedure ReadA(out Value: string); reintroduce; overload; virtual; abstract;
//    procedure WriteA(const Value: string); reintroduce; overload; virtual; abstract;
//    {$ENDIF}

    // Unicode strings
    procedure ReadW(out Value: UnicodeString); reintroduce; overload; virtual; abstract;
    procedure WriteW(const Value: UnicodeString); reintroduce; overload; virtual; abstract;

    function Write(const Buffer; Count: Longint): Longint; overload; override;

    procedure Write(const Value: TKMDirection  ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMPoint      ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMPointW     ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMPointF     ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMPointDir   ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMRangeInt   ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMRangeSingle); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TKMRect       ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Single        ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Extended      ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Integer       ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Cardinal      ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Byte          ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Boolean       ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: Word          ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: ShortInt      ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: SmallInt      ); reintroduce; overload; virtual; abstract;
    procedure Write(const Value: TDateTime     ); reintroduce; overload; virtual; abstract;

    procedure Read(out Value: TKMDirection  ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMPoint      ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMPointW     ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMPointF     ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMPointDir   ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMRangeInt   ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMRangeSingle); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TKMRect       ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Single        ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Extended      ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Integer       ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Cardinal      ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Byte          ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Boolean       ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: Word          ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: ShortInt      ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: SmallInt      ); reintroduce; overload; virtual; abstract;
    procedure Read(out Value: TDateTime     ); reintroduce; overload; virtual; abstract;

    procedure ReadBytes(out Value: TBytes);
    procedure WriteBytes(const Value: TBytes);

    //ZLib's decompression streams don't work with the normal TStreams.CopyFrom since
    //it uses ReadBuffer. This procedure will work when Source is a TDecompressionStream
    procedure CopyFromDecompression(Source: TStream);

    procedure SaveToFileCompressed(const aFileName: string; const aMarker: string);
    procedure LoadFromFileCompressed(const aFileName: string; const aMarker: string);

    class procedure AsyncSaveToFileAndFree(var aStream; const aFileName: string; aWorkerThread: TKMWorkerThread);
    class procedure AsyncSaveToFileCompressedAndFree(var aStream; const aFileName: string; const aMarker: string; aWorkerThread: TKMWorkerThread);
  end;

  // Extended with custom Read/Write commands which accept various types without asking for their length
  TKMemoryStreamBinary = class(TKMemoryStream)
  public
    // Assert savegame sections
    procedure CheckMarker(const aTitle: string); override;
    procedure PlaceMarker(const aTitle: string); override;

    procedure ReadANSI(out aValue: string); override;
    procedure WriteANSI(const aValue: string); override;

//    {$IFDEF DESKTOP}
    //Legacy format for campaigns info, maxlength 65k ansichars
    procedure ReadA(out Value: AnsiString); override;
    procedure WriteA(const Value: AnsiString); override;
//    {$ENDIF}
//    {$IFDEF TABLET}
//    //Legacy format for campaigns info, maxlength 65k ansichars
//    procedure ReadA(out Value: string); override;
//    procedure WriteA(const Value: string); override;
//    {$ENDIF}

    // Unicode strings
    procedure ReadW(out Value: UnicodeString); override;
    procedure WriteW(const Value: UnicodeString); override;

    function Write(const Buffer; Count: Longint): Longint; override;

    procedure Write(const Value: TKMDirection  ); override;
    procedure Write(const Value: TKMPoint      ); override;
    procedure Write(const Value: TKMPointW     ); override;
    procedure Write(const Value: TKMPointF     ); override;
    procedure Write(const Value: TKMPointDir   ); override;
    procedure Write(const Value: TKMRangeInt   ); override;
    procedure Write(const Value: TKMRangeSingle); override;
    procedure Write(const Value: TKMRect       ); override;
    procedure Write(const Value: Single        ); override;
    procedure Write(const Value: Extended      ); override;
    procedure Write(const Value: Integer       ); override;
    procedure Write(const Value: Cardinal      ); override;
    procedure Write(const Value: Byte          ); override;
    procedure Write(const Value: Boolean       ); override;
    procedure Write(const Value: Word          ); override;
    procedure Write(const Value: ShortInt      ); override;
    procedure Write(const Value: SmallInt      ); override;
    procedure Write(const Value: TDateTime     ); override;

    procedure Read(out Value: TKMDirection  ); override;
    procedure Read(out Value: TKMPoint      ); override;
    procedure Read(out Value: TKMPointW     ); override;
    procedure Read(out Value: TKMPointF     ); override;
    procedure Read(out Value: TKMPointDir   ); override;
    procedure Read(out Value: TKMRangeInt   ); override;
    procedure Read(out Value: TKMRangeSingle); override;
    procedure Read(out Value: TKMRect       ); override;
    procedure Read(out Value: Single        ); override;
    procedure Read(out Value: Extended      ); override;
    procedure Read(out Value: Integer       ); override;
    procedure Read(out Value: Cardinal      ); override;
    procedure Read(out Value: Byte          ); override;
    procedure Read(out Value: Boolean       ); override;
    procedure Read(out Value: Word          ); override;
    procedure Read(out Value: ShortInt      ); override;
    procedure Read(out Value: SmallInt      ); override;
    procedure Read(out Value: TDateTime     ); override;
  end;

  // Text writer
  TKMemoryStreamText = class(TKMemoryStream)
  private
    fLastSection: string;
    procedure WriteText(const aString: string);
  public
    procedure PlaceMarker(const aTitle: string); override;

    procedure WriteANSI(const aValue: string); override;
    procedure WriteA(const Value: AnsiString); override;
    procedure WriteW(const Value: UnicodeString); override;

    function Write(const Buffer; Count: Longint): Longint; override;

    procedure Write(const Value: TKMDirection  ); override;
    procedure Write(const Value: TKMPoint      ); override;
    procedure Write(const Value: TKMPointW     ); override;
    procedure Write(const Value: TKMPointF     ); override;
    procedure Write(const Value: TKMPointDir   ); override;
    procedure Write(const Value: TKMRangeInt   ); override;
    procedure Write(const Value: TKMRangeSingle); override;
    procedure Write(const Value: TKMRect       ); override;
    procedure Write(const Value: Single        ); override;
    procedure Write(const Value: Extended      ); override;
    procedure Write(const Value: Integer       ); override;
    procedure Write(const Value: Cardinal      ); override;
    procedure Write(const Value: Byte          ); override;
    procedure Write(const Value: Boolean       ); override;
    procedure Write(const Value: Word          ); override;
    procedure Write(const Value: ShortInt      ); override;
    procedure Write(const Value: SmallInt      ); override;
    procedure Write(const Value: TDateTime     ); override;

    //Not implemented methods yet
    procedure CheckMarker(const aTitle: string); override;

    procedure ReadANSI(out aValue: string); override;
    procedure ReadA(out Value: AnsiString); override;
    procedure ReadW(out Value: UnicodeString); override;

    procedure Read(out Value: TKMDirection  ); override;
    procedure Read(out Value: TKMPoint      ); override;
    procedure Read(out Value: TKMPointW     ); override;
    procedure Read(out Value: TKMPointF     ); override;
    procedure Read(out Value: TKMPointDir   ); override;
    procedure Read(out Value: TKMRangeInt   ); override;
    procedure Read(out Value: TKMRangeSingle); override;
    procedure Read(out Value: TKMRect       ); override;
    procedure Read(out Value: Single        ); override;
    procedure Read(out Value: Extended      ); override;
    procedure Read(out Value: Integer       ); override;
    procedure Read(out Value: Cardinal      ); override;
    procedure Read(out Value: Byte          ); override;
    procedure Read(out Value: Boolean       ); override;
    procedure Read(out Value: Word          ); override;
    procedure Read(out Value: ShortInt      ); override;
    procedure Read(out Value: SmallInt      ); override;
    procedure Read(out Value: TDateTime     ); override;


  end;


  TStreamEvent = procedure (aData: TKMemoryStream) of object;
  TStreamIntEvent = procedure (aData: TKMemoryStream; aSenderIndex: ShortInt) of object;

  //TXStringList using integer values, instead of its String represantation, when sorted
  TXStringList = class(TStringList)
  protected
    function CompareStrings(const S1, S2: string): Integer; override;
  end;


  //TKMList owns items and frees them when they are deleted from the list
  TKMList = class(TList)
  protected
    //This one function is enough to free all deleted/cleared/rewritten objects
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  end;

  TKMPointList = class
  private
    fCount: Integer;
    fItems: array of TKMPoint; //0..Count-1
    function GetPoint(aIndex: Integer): TKMPoint; inline;
    procedure SetPoint(aIndex: Integer; const aValue: TKMPoint); inline; //1..Count
    function GetLast: TKMPoint;
    function GetLen: Single;
  public
    constructor Create;

    property Count: Integer read fCount write fCount;
    property Items[aIndex: Integer]: TKMPoint read GetPoint write SetPoint; default;
    property Last: TKMPoint read GetLast;
    function IsEmpty: Boolean;
    property Len: Single read GetLen;

    procedure Clear; virtual;
    procedure Copy(aSrc: TKMPointList);
    procedure Add(const aLoc: TKMPoint); virtual;
    procedure AddList(aList: TKMPointList);
    procedure AddUnique(const aLoc: TKMPoint);
    procedure AddListUnique(aList: TKMPointList);
    function  Remove(const aLoc: TKMPoint): Integer; virtual;
    procedure Delete(aIndex: Integer); virtual;
    procedure Insert(ID: Integer; const aLoc: TKMPoint);
    function  GetRandom(out Point: TKMPoint): Boolean;
    function  GetClosest(const aLoc: TKMPoint; out Point: TKMPoint): Boolean;
    function Contains(const aLoc: TKMPoint): Boolean;
    function IndexOf(const aLoc: TKMPoint): Integer;
    procedure Inverse;
    procedure SparseToDense;
    function  GetBounds(out Bounds: TKMRect): Boolean;
    procedure SaveToStream(SaveStream: TKMemoryStream); virtual;
    procedure LoadFromStream(LoadStream: TKMemoryStream); virtual;
  end;

  TKMPointListArray = array of TKMPointList;

  TKMWeightedPointList = class(TKMPointList)
    fWeight: array of Single;
  public
    procedure Add(const aLoc: TKMPoint; aWeight: Single); reintroduce;
    function GetWeightedRandom(out Point: TKMPoint): Boolean;
  end;

  TKMPointCenteredList = class(TKMWeightedPointList)
  private
    fCenter: TKMPoint;
  public
    constructor Create(aCenter: TKMPoint);
    procedure Add(const aLoc: TKMPoint); reintroduce;
  end;

  TKMPointTagList = class(TKMPointList)
  public
    Tag, Tag2: array of Cardinal; //0..Count-1
    procedure Clear; override;
    procedure Add(const aLoc: TKMPoint; aTag: Cardinal; aTag2: Cardinal = 0); reintroduce; virtual;
    function IndexOf(const aLoc: TKMPoint; aTag: Cardinal; aTag2: Cardinal): Integer; overload;
    procedure SortByTag;
    function Remove(const aLoc: TKMPoint): Integer; override;
    procedure Delete(aIndex: Integer); override;
    procedure SaveToStream(SaveStream: TKMemoryStream); override;
    procedure LoadFromStream(LoadStream: TKMemoryStream); override;
  end;


  TKMPointDirList = class //Used for finding fishing places, fighting positions, etc.
  private
    fItems: array of TKMPointDir; //0..Count-1
    fCount: Integer;
    function GetItem(aIndex: Integer): TKMPointDir;
  public
    procedure Clear;
    procedure Add(const aLoc: TKMPointDir); virtual;
    property Count: Integer read fCount;
    property Items[aIndex: Integer]: TKMPointDir read GetItem; default;
    function GetRandom(out Point: TKMPointDir): Boolean; //overload;

//    function GetRandom(aCloseToLoc: TKMPoint; out Point: TKMPointDir): Boolean; overload;
    procedure ToPointList(aList: TKMPointList; aUnique: Boolean);
    procedure LoadFromStream(LoadStream: TKMemoryStream); virtual;
    procedure SaveToStream(SaveStream: TKMemoryStream); virtual;
  end;


  TKMPointDirCenteredList = class(TKMPointDirList)
  private
    fCenter: TKMPoint;
    fWeight: array of Single;
  public
    constructor Create(aCenter: TKMPoint);
    procedure Add(const aLoc: TKMPointDir); override;
    function GetWeightedRandom(out Point: TKMPointDir): Boolean;
  end;


  TKMPointDirTagList = class(TKMPointDirList)
  public
    Tag: array of Cardinal; //0..Count-1
    procedure Add(const aLoc: TKMPointDir; aTag: Cardinal); reintroduce;
    procedure SortByTag;
    procedure SaveToStream(SaveStream: TKMemoryStream); override;
    procedure LoadFromStream(LoadStream: TKMemoryStream); override;
  end;


  TKMPointCounterList = class(TKMPointTagList)
  private
//    fAppearences: array of Word;
  public
    procedure Add(const aLoc: TKMPoint; aTag2: Cardinal = 0); reintroduce;
    procedure AddNew(const aLoc: TKMPoint; aTag2: Cardinal = 0);
    function GetPointsCnt(aIndex: Integer): Word; overload;
    function GetPointsCnt(const aLoc: TKMPoint): Word; overload;
  end;


  TKMMapsCRCList = class
  private
    fEnabled: Boolean;
    fMapsList: TStringList;
    fOnMapsUpdate: TUnicodeStringEvent;

    procedure MapsUpdated;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromString(const aString: UnicodeString);
    function PackToString: UnicodeString;

    property OnMapsUpdate: TUnicodeStringEvent read fOnMapsUpdate write fOnMapsUpdate;
    property Count: Integer read GetCount;
    property Enabled: Boolean read fEnabled write fEnabled;

    procedure Clear;
    procedure RemoveMissing(aMapsCRCArray: TKMCardinalArray);
    function Contains(aMapCRC: Cardinal): Boolean;
    procedure Add(aMapCRC: Cardinal);
    procedure Remove(aMapCRC: Cardinal);
    procedure Replace(aOldCRC, aNewCRC: Cardinal);
  end;


  //Custom Exception that includes a TKMPoint
  ELocError = class(Exception)
    Loc: TKMPoint;
    constructor Create(const aMsg: UnicodeString; const aLoc: TKMPoint);
  end;


implementation
uses
  Math,
  {$IFDEF FPC} zstream, {$ENDIF}
  {$IFDEF WDC} ZLib, {$ENDIF}
  KM_CommonUtils;

const
  MAPS_CRC_DELIMITER = ':';

{TXStringList}
//List custom comparation, using Integer value, instead of its String represantation
function TXStringList.CompareStrings(const S1, S2: string): Integer;
var
  i1, i2, e1, e2: Integer;
begin
  Val(S1, i1, e1);
  Assert((e1 = 0) or (S1[e1] = NameValueSeparator));
  Val(S2, i2, e2);
  Assert((e2 = 0) or (S2[e2] = NameValueSeparator));
  Result := CompareValue(i1, i2);
end;


{ ELocError }
constructor ELocError.Create(const aMsg: UnicodeString; const aLoc: TKMPoint);
begin
  inherited Create(aMsg);
  Loc := aLoc;
end;


{ TKMList }
// We were notified that the item is deleted from the list
procedure TKMList.Notify(Ptr: Pointer; Action: TListNotification);
begin
  inherited;
  if (Action = lnDeleted) then
    TObject(Ptr).Free;
end;


procedure TKMemoryStream.ReadBytes(out Value: TBytes);
var
  I: Word;
begin
  Read(I, SizeOf(I));
  SetLength(Value, I);
  if I > 0 then
    Read(Pointer(Value)^, I);
end;


procedure TKMemoryStream.WriteBytes(const Value: TBytes);
var
  I: Word;
begin
  I := Length(Value);
  inherited Write(I, SizeOf(I));
  if I = 0 then Exit;
  inherited Write(Pointer(Value)^, I);
end;


class procedure TKMemoryStream.AsyncSaveToFileAndFree(var aStream;
  const aFileName: string; aWorkerThread: TKMWorkerThread);
var
  LocalStream: TKMemoryStream;
begin
  Assert(TObject(aStream) is TKMemoryStream);
  LocalStream := TKMemoryStream(aStream);
  Pointer(aStream) := nil; //So caller doesn't use it by mistake
  aWorkerThread.QueueWork(procedure
  begin
    try
      LocalStream.SaveToFile(aFileName);
    finally
      LocalStream.Free;
    end;
  end);
end;


class procedure TKMemoryStream.AsyncSaveToFileCompressedAndFree(
  var aStream; const aFileName: string; const aMarker: string;
  aWorkerThread: TKMWorkerThread);
var
  LocalStream: TKMemoryStream;
begin
  Assert(TObject(aStream) is TKMemoryStream);
  LocalStream := TKMemoryStream(aStream);
  Pointer(aStream) := nil; //So caller doesn't use it by mistake
  aWorkerThread.QueueWork(procedure
  begin
    try
      LocalStream.SaveToFileCompressed(aFileName, aMarker);
    finally
      LocalStream.Free;
    end;
  end);
end;


procedure TKMemoryStream.CopyFromDecompression(Source: TStream);
const
  MaxBufSize = $F000;
var
  Count: Integer;
  Buffer: PByte;
begin
  Source.Position := 0;
  GetMem(Buffer, MaxBufSize);
  try
    Count := Source.Read(Buffer^, MaxBufSize);
    while Count > 0 do
    begin
      WriteBuffer(Buffer^, Count);
      Count := Source.Read(Buffer^, MaxBufSize);
    end;
  finally
    FreeMem(Buffer, MaxBufSize);
  end;
end;


procedure TKMemoryStream.SaveToFileCompressed(const aFileName: string; const aMarker: string);
var
  S: TKMemoryStreamBinary;
  CS: TCompressionStream;
begin
  S := TKMemoryStreamBinary.Create;
  try
    S.PlaceMarker(aMarker);

    CS := TCompressionStream.Create(cldefault, S);
    try
      CS.CopyFrom(Self, 0);
    finally
      CS.Free;
    end;

    S.SaveToFile(aFileName);
  finally
    S.Free;
  end;
end;


procedure TKMemoryStream.LoadFromFileCompressed(const aFileName: string; const aMarker: string);
var
  S: TKMemoryStreamBinary;
  DS: TDecompressionStream;
begin
  S := TKMemoryStreamBinary.Create;
  try
    S.LoadFromFile(aFileName);
    S.CheckMarker(aMarker);
    DS := TDecompressionStream.Create(S);
    try
      CopyFromDecompression(DS);
      Position := 0;
    finally
      DS.Free;
    end;
  finally
    S.Free;
  end;
end;


{ TKMPointList }
constructor TKMPointList.Create;
begin
  inherited;
end;


procedure TKMPointList.Clear;
begin
  fCount := 0;
end;


procedure TKMPointList.Add(const aLoc: TKMPoint);
begin
  if fCount >= Length(fItems) then
    SetLength(fItems, fCount + 32);
  fItems[fCount] := aLoc;
  Inc(fCount);
end;


procedure TKMPointList.AddList(aList: TKMPointList);
var
  I: Integer;
begin
  for I := 0 to aList.Count - 1 do
    Add(aList[I]);
end;


procedure TKMPointList.AddUnique(const aLoc: TKMPoint);
begin
  if not Contains(aLoc) then
    Add(aLoc);
end;


procedure TKMPointList.AddListUnique(aList: TKMPointList);
var
  I: Integer;
begin
  for I := 0 to aList.Count - 1 do
    AddUnique(aList[I]);
end;


//Remove point from the list if is there. Return index of removed entry or -1 on failure
function TKMPointList.Remove(const aLoc: TKMPoint): Integer;
var
  I: Integer;
begin
  Result := -1;

  //Scan whole list to detect duplicate entries
  for I := 0 to fCount - 1 do
    if KMSamePoint(fItems[I], aLoc) then
      Result := I;

  //Remove found entry
  if (Result <> -1) then
    Delete(Result);
end;


procedure TKMPointList.Delete(aIndex: Integer);
begin
  if not InRange(aIndex, 0, Count-1) then Exit;
  if (aIndex <> fCount - 1) then
    Move(fItems[aIndex+1], fItems[aIndex], SizeOf(fItems[aIndex]) * (fCount - 1 - aIndex));
  Dec(fCount);
end;


//Insert an entry and check if list is still walkable
//Walkable means that every point is next to neighbour points }
procedure TKMPointList.Insert(ID: Integer; const aLoc: TKMPoint);
begin
  Assert(InRange(ID, 0, fCount));

  //Grow the list
  if fCount >= Length(fItems) then
    SetLength(fItems, fCount + 32);

  //Shift items towards end
  if fCount <> 0 then
    Move(fItems[ID], fItems[ID+1], SizeOf(fItems[ID]) * (fCount - ID));

  fItems[ID] := aLoc;
  Inc(fCount);
end;


function TKMPointList.GetRandom(out Point: TKMPoint): Boolean;
begin
  Result := fCount <> 0;
  if Result then
    Point := fItems[KaMRandom(fCount, 'TKMPointList.GetRandom')];
end;


function TKMPointList.GetClosest(const aLoc: TKMPoint; out Point: TKMPoint): Boolean;
var
  I: Integer;
begin
  Result := fCount <> 0;
  if Result then
  begin
    Point := fItems[0];
    for I := 1 to fCount - 1 do
    if KMLengthSqr(fItems[I], aLoc) < KMLengthSqr(Point, aLoc) then
      Point := fItems[I];
  end;
end;


function TKMPointList.Contains(const aLoc: TKMPoint): Boolean;
begin
  Result := IndexOf(aLoc) <> -1;
end;


function TKMPointList.IndexOf(const aLoc: TKMPoint): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := fCount - 1 downto 0 do
  if KMSamePoint(aLoc, fItems[I]) then
  begin
    Result := I;
    Break;
  end;
end;


function TKMPointList.GetLast: TKMPoint;
begin
  if IsEmpty then
    raise Exception.Create('No points in list');
  Result := fItems[fCount - 1];
end;


function TKMPointList.IsEmpty: Boolean;
begin
  Result := fCount = 0;
end;


procedure TKMPointList.Copy(aSrc: TKMPointList);
begin
  fCount := aSrc.Count;
  SetLength(fItems, fCount);

  Move(aSrc.fItems[0], fItems[0], SizeOf(fItems[0]) * fCount);
end;


function TKMPointList.GetPoint(aIndex: Integer): TKMPoint;
begin
  Result := fItems[aIndex];
end;


procedure TKMPointList.SetPoint(aIndex: Integer; const aValue: TKMPoint);
begin
  fItems[aIndex] := aValue;
end;


function TKMPointList.GetLen: Single;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to fCount - 2 do
    Result := Result + KMLengthDiag(fItems[I], fItems[I + 1]);
end;


//Reverse the list
procedure TKMPointList.Inverse;
var
  I: Integer;
begin
  for I := 0 to fCount div 2 - 1 do
    KMSwapPoints(fItems[I], fItems[fCount-1-I]);
end;


//Used in JPS pathfinding
//Take the sparse walk route with nodes in corners (A------B)
//and add all the missing nodes inbetween like so: (A123456B)
procedure TKMPointList.SparseToDense;
var
  I,K,J: Integer;
  Tmp: array of TKMPoint;
  Span: Word;
  C,N: ^TKMPoint;
begin
  K := 0;
  SetLength(Tmp, 8192);
  for I := 0 to fCount - 1 do
  begin
    Tmp[K] := fItems[I];
    Inc(K);

    if (I <> fCount - 1) then
    begin
      C := @fItems[I];
      N := @fItems[I+1];
      Span := Max(Abs(N.X - C.X), Abs(N.Y - C.Y));
      for J := 1 to Span - 1 do
      begin
        Tmp[K].X := C.X + Round((N.X - C.X) / Span * J);
        Tmp[K].Y := C.Y + Round((N.Y - C.Y) / Span * J);
        Inc(K);
      end;
    end;
  end;

  fCount := K;
  SetLength(fItems, fCount);
  Move(Tmp[0], fItems[0], SizeOf(fItems[0]) * fCount);
end;


function TKMPointList.GetBounds(out Bounds: TKMRect): Boolean;
var I: Integer;
begin
  Result := fCount <> 0;

  if Result then
  begin
    //Something to start with
    Bounds.Left   := fItems[0].X;
    Bounds.Top    := fItems[0].Y;
    Bounds.Right  := fItems[0].X;
    Bounds.Bottom := fItems[0].Y;
    for I := 1 to fCount - 1 do
    begin
      if fItems[I].X < Bounds.Left then Bounds.Left := fItems[I].X;
      if fItems[I].Y < Bounds.Top then Bounds.Top := fItems[I].Y;
      if fItems[I].X > Bounds.Right then Bounds.Right := fItems[I].X;
      if fItems[I].Y > Bounds.Bottom then Bounds.Bottom := fItems[I].Y;
    end;
  end;
end;


procedure TKMPointList.SaveToStream(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fCount);
  if fCount > 0 then
    SaveStream.Write(fItems[0], SizeOf(fItems[0]) * fCount);
end;


procedure TKMPointList.LoadFromStream(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(fCount);
  SetLength(fItems, fCount);
  if fCount > 0 then
    LoadStream.Read(fItems[0], SizeOf(fItems[0]) * fCount);
end;


{ TKMWeightedList }
procedure TKMWeightedPointList.Add(const aLoc: TKMPoint; aWeight: Single);
begin
  inherited Add(aLoc);

  if fCount >= Length(fWeight) then
    SetLength(fWeight, fCount + 32);

  fWeight[fCount - 1] := aWeight;
end;


function TKMWeightedPointList.GetWeightedRandom(out Point: TKMPoint): Boolean;
var
  I: Integer;
  WeightsSum, Rnd: Extended;
begin
  Result := False;

  if Count = 0 then
    Exit;

  WeightsSum := 0;
  for I := 0 to fCount - 1 do
    WeightsSum := WeightsSum + fWeight[I];

  Rnd := KaMRandomS1(WeightsSum, 'TKMPointCenteredList.GetWeightedRandom');

  for I := 0 to fCount - 1 do
  begin
    if Rnd < fWeight[I] then
    begin
      Point := fItems[I];
      Exit(True);
    end;
    Rnd := Rnd - fWeight[I];
  end;
  Assert(False, 'Error getting weighted random');
end;


{ TKMPointCenteredList }
constructor TKMPointCenteredList.Create(aCenter: TKMPoint);
begin
  inherited Create;
  fCenter := aCenter;
end;


procedure TKMPointCenteredList.Add(const aLoc: TKMPoint);
const
  BASE_VAL = 100;
var
  Len, Weight: Single;
begin
  Len := KMLength(fCenter, aLoc);
  //Special case when we aLoc is in the center
  if Len = 0 then
    Weight := BASE_VAL * 2
  else
    Weight := BASE_VAL / Len; //smaller weight for distant locs

  inherited Add(aLoc, Weight);
end;


{ TKMPointTagList }
procedure TKMPointTagList.Clear;
begin
  inherited;
end;


procedure TKMPointTagList.Add(const aLoc: TKMPoint; aTag: Cardinal; aTag2: Cardinal = 0);
begin
  inherited Add(aLoc);

  if fCount >= Length(Tag) then  SetLength(Tag, fCount + 32); //Expand the list
  if fCount >= Length(Tag2) then SetLength(Tag2, fCount + 32); //+32 is just a way to avoid further expansions
  Tag[fCount-1]  := aTag;
  Tag2[fCount-1] := aTag2;
end;


function TKMPointTagList.IndexOf(const aLoc: TKMPoint; aTag, aTag2: Cardinal): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := fCount - 1 downto 0 do
  if KMSamePoint(aLoc, fItems[I]) and (aTag = Tag[I]) and (aTag2 = Tag2[I]) then
  begin
    Result := I;
    Break;
  end;
end;


function TKMPointTagList.Remove(const aLoc: TKMPoint): Integer;
begin
  Result := inherited Remove(aLoc);
  //Tags are moved by Delete function. No need to move them here
end;


procedure TKMPointTagList.Delete(aIndex: Integer);
begin
  if not InRange(aIndex, 0, Count - 1) or (Count = 0) then Exit;

  inherited Delete(aIndex);

  //Note that fCount is already decreased by 1
  if (aIndex <> fCount) then
  begin
    Move(Tag[aIndex+1], Tag[aIndex], SizeOf(Tag[aIndex]) * (fCount - aIndex));
    Move(Tag2[aIndex+1], Tag2[aIndex], SizeOf(Tag2[aIndex]) * (fCount - aIndex));
  end;
end;


procedure TKMPointTagList.SaveToStream(SaveStream: TKMemoryStream);
begin
  inherited; //Writes Count

  if fCount > 0 then
  begin
    SaveStream.Write(Tag[0], SizeOf(Tag[0]) * fCount);
    SaveStream.Write(Tag2[0], SizeOf(Tag2[0]) * fCount);
  end;
end;


procedure TKMPointTagList.SortByTag;
  // Quicksort implementation (because there is not specified count of elements buble does not give any sense)
  procedure QuickSort(MinIdx,MaxIdx: Integer);
  var
    I,K,X: Integer;
  begin
    I := MinIdx;
    K := MaxIdx;
    X := Tag[ (MinIdx+MaxIdx) div 2 ];
    repeat
      while (Tag[I] < X) do
        I := I + 1;
      while (X < Tag[K]) do
        K := K - 1;
      if (I <= K) then
      begin
        KMSwapPoints(fItems[I], fItems[K]);
        KMSwapInt(Tag[I], Tag[K]);
        KMSwapInt(Tag2[I], Tag2[K]);
        I := I + 1;
        K := K - 1;
      end;
    until (I > K);
    if (MinIdx < K) then
      QuickSort(MinIdx,K);
    if (I < MaxIdx) then
      QuickSort(I,MaxIdx);
  end;

//var I,K: Integer;
begin
  // Buble sort
  //for I := 0 to fCount - 1 do
  //  for K := I + 1 to fCount - 1 do
  //    if Tag[K] < Tag[I] then
  //    begin
  //      KMSwapPoints(fItems[I], fItems[K]);
  //      KMSwapInt(Tag[I], Tag[K]);
  //      KMSwapInt(Tag2[I], Tag2[K]);
  //    end;
  if (fCount > 1) then
    QuickSort(0, fCount - 1);
end;


procedure TKMPointTagList.LoadFromStream(LoadStream: TKMemoryStream);
begin
  inherited; //Reads Count

  SetLength(Tag, fCount);
  SetLength(Tag2, fCount);
  if fCount > 0 then
  begin
    LoadStream.Read(Tag[0], SizeOf(Tag[0]) * fCount);
    LoadStream.Read(Tag2[0], SizeOf(Tag2[0]) * fCount);
  end;
end;


{ TKMPointList }
procedure TKMPointDirList.Clear;
begin
  fCount := 0;
end;


procedure TKMPointDirList.Add(const aLoc: TKMPointDir);
begin
  if fCount >= Length(fItems) then
    SetLength(fItems, fCount + 32);
  fItems[fCount] := aLoc;
  inc(fCount);
end;


function TKMPointDirList.GetItem(aIndex: Integer): TKMPointDir;
begin
  Assert(InRange(aIndex, 0, fCount - 1));
  Result := fItems[aIndex];
end;


function TKMPointDirList.GetRandom(out Point: TKMPointDir):Boolean;
begin
  Result := False;
  if fCount > 0 then
  begin
    Point := fItems[KaMRandom(fCount, 'TKMPointDirList.GetRandom')];
    Result := True;
  end;
end;


procedure TKMPointDirList.ToPointList(aList: TKMPointList; aUnique: Boolean);
var
  I: Integer;
begin
  for I := 0 to fCount - 1 do
    if aUnique then
      aList.AddUnique(fItems[I].Loc)
    else
      aList.Add(fItems[I].Loc)
end;


procedure TKMPointDirList.SaveToStream(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fCount);
  if fCount > 0 then
    SaveStream.Write(fItems[0], SizeOf(fItems[0]) * fCount);
end;


procedure TKMPointDirList.LoadFromStream(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(fCount);
  SetLength(fItems, fCount);
  if fCount > 0 then
    LoadStream.Read(fItems[0], SizeOf(fItems[0]) * fCount);
end;


{ TKMPointDirCenteredList }
constructor TKMPointDirCenteredList.Create(aCenter: TKMPoint);
begin
  inherited Create;
  fCenter := aCenter;
end;


procedure TKMPointDirCenteredList.Add(const aLoc: TKMPointDir);
const
  BASE_VAL = 100;
var
  Len: Single;
begin
  inherited;

  if fCount >= Length(fWeight) then
    SetLength(fWeight, fCount + 32);

  Len := KMLength(fCenter, aLoc.Loc);
  //Special case when we aLoc is in the center
  if Len = 0 then
    fWeight[fCount - 1] := BASE_VAL * 2
  else
    fWeight[fCount - 1] := BASE_VAL / Len; //smaller weight for distant locs
end;


function TKMPointDirCenteredList.GetWeightedRandom(out Point: TKMPointDir): Boolean;
var
  I: Integer;
  WeightsSum, Rnd: Single;
begin
  Result := False;

  if Count = 0 then
    Exit;

  WeightsSum := 0;
  for I := 0 to fCount - 1 do
    WeightsSum := WeightsSum + fWeight[I];

  Rnd := KaMRandomS1(WeightsSum, 'TKMPointDirCenteredList.GetWeightedRandom');

  for I := 0 to fCount - 1 do
  begin
    if Rnd < fWeight[I] then
    begin
      Point := fItems[I];
      Exit(True);
    end;
    Rnd := Rnd - fWeight[I];
  end;
  Assert(False, 'Error getting weighted random');
end;


{ TKMPointDirTagList }
procedure TKMPointDirTagList.Add(const aLoc: TKMPointDir; aTag: Cardinal);
begin
  inherited Add(aLoc);

  if fCount >= Length(Tag) then SetLength(Tag, fCount + 32); //Expand the list
  Tag[fCount-1] := aTag;
end;


procedure TKMPointDirTagList.SortByTag;
var
  I, K: Integer;
begin
  for I := 0 to fCount - 1 do
  for K := I + 1 to fCount - 1 do
  if Tag[K] < Tag[I] then
  begin
    KMSwapPointDir(fItems[I], fItems[K]);
    KMSwapInt(Tag[I], Tag[K]);
  end;
end;


procedure TKMPointDirTagList.SaveToStream(SaveStream: TKMemoryStream);
begin
  inherited; //Writes Count

  if fCount > 0 then
    SaveStream.Write(Tag[0], SizeOf(Tag[0]) * fCount);
end;


procedure TKMPointDirTagList.LoadFromStream(LoadStream: TKMemoryStream);
begin
  inherited; //Reads Count

  SetLength(Tag, fCount);
  if fCount > 0 then
    LoadStream.Read(Tag[0], SizeOf(Tag[0]) * fCount);
end;


{ TKMPointCounterList }
procedure TKMPointCounterList.Add(const aLoc: TKMPoint; aTag2: Cardinal = 0);
var
  Ind: Integer;
begin
  Ind := IndexOf(aLoc);
  if Ind <> -1 then
    Tag[Ind] := Tag[Ind] + 1
  else
    inherited Add(aLoc, 1, aTag2);
end;


procedure TKMPointCounterList.AddNew(const aLoc: TKMPoint; aTag2: Cardinal = 0);
begin
  if Contains(aLoc) then Exit;

  inherited Add(aLoc, 1, aTag2);
end;


function TKMPointCounterList.GetPointsCnt(aIndex: Integer): Word;
begin
  Result := Tag[aIndex];
end;


function TKMPointCounterList.GetPointsCnt(const aLoc: TKMPoint): Word;
var
  Ind: Integer;
begin
  Ind := IndexOf(aLoc);
  if Ind = -1 then
    Result := 0
  else
    Result := Tag[Ind];
end;


{ TKMMapsCRCList }
constructor TKMMapsCRCList.Create;
begin
  inherited Create;

  fEnabled := True;
  fMapsList := TStringList.Create;
  fMapsList.Delimiter       := MAPS_CRC_DELIMITER;
  fMapsList.StrictDelimiter := True; // Requires D2006 or newer.
end;


destructor TKMMapsCRCList.Destroy;
begin
  FreeAndNil(fMapsList);
  inherited;
end;


function TKMMapsCRCList.GetCount: Integer;
begin
  if not fEnabled then Exit(0);

  Result := fMapsList.Count;
end;


procedure TKMMapsCRCList.MapsUpdated;
begin
  if Assigned(fOnMapsUpdate) then
    fOnMapsUpdate(PackToString);
end;


procedure TKMMapsCRCList.LoadFromString(const aString: UnicodeString);
var
  I: Integer;
  MapCRC : Int64;
  StringList: TStringList;
begin
  if not fEnabled then Exit;

  fMapsList.Clear;
  StringList := TStringList.Create;
  StringList.Delimiter := MAPS_CRC_DELIMITER;
  StringList.DelimitedText   := Trim(aString);

  for I := 0 to StringList.Count - 1 do
  begin
    if TryStrToInt64(Trim(StringList[I]), MapCRC)
      and (MapCRC > 0)
      and not Contains(Cardinal(MapCRC)) then
      fMapsList.Add(Trim(StringList[I]));
  end;

  StringList.Free;
end;


function TKMMapsCRCList.PackToString: UnicodeString;
begin
  if not fEnabled then Exit('');

  Result := fMapsList.DelimitedText;
end;


procedure TKMMapsCRCList.Clear;
begin
  if not fEnabled then Exit;

  fMapsList.Clear;
end;


//Remove missing Favourites Maps from list, check if are of them are presented in the given maps CRC array.
procedure TKMMapsCRCList.RemoveMissing(aMapsCRCArray: TKMCardinalArray);
  function ArrayContains(aValue: Cardinal): Boolean;
  var I: Integer;
  begin
    Result := False;
    for I := Low(aMapsCRCArray) to High(aMapsCRCArray) do
      if aMapsCRCArray[I] = aValue then
      begin
        Result := True;
        Break;
      end;
  end;
var I: Integer;
begin
  if not fEnabled then Exit;

  I := fMapsList.Count - 1;
  //We must check, that all values from favorites are presented in maps CRC array. If not - then remove it from favourites
  while (fMapsList.Count > 0) and (I >= 0) do
  begin
    if not ArrayContains(StrToInt64(fMapsList[I])) then
    begin
      fMapsList.Delete(I);
      MapsUpdated;
    end;

    Dec(I);
  end;
end;


function TKMMapsCRCList.Contains(aMapCRC: Cardinal): Boolean;
begin
  if not fEnabled then Exit(False);

  Result := fMapsList.IndexOf(IntToStr(aMapCRC)) <> -1;
end;


procedure TKMMapsCRCList.Add(aMapCRC: Cardinal);
begin
  if not fEnabled then Exit;

  if not Contains(aMapCRC) then
  begin
    fMapsList.Add(IntToStr(aMapCRC));
    MapsUpdated;
  end;
end;


procedure TKMMapsCRCList.Remove(aMapCRC: Cardinal);
var
  index: Integer;
begin
  if not fEnabled then Exit;

  index := fMapsList.IndexOf(IntToStr(aMapCRC));
  if index <> -1 then
    fMapsList.Delete(index);

  MapsUpdated;
end;


procedure TKMMapsCRCList.Replace(aOldCRC, aNewCRC: Cardinal);
begin
  if not fEnabled then Exit;

  if Contains(aOldCRC) then
  begin
    Remove(aOldCRC);
    Add(aNewCRC);
  end;
end;


{ TKMemoryStream }
procedure TKMemoryStream.ReadHugeString(out Value: AnsiString);
var I: Cardinal;
begin
  Read(I, SizeOf(I));
  SetLength(Value, I);
  if I > 0 then
    Read(Pointer(Value)^, I);
end;


procedure TKMemoryStream.WriteHugeString(const Value: AnsiString);
var I: Cardinal;
begin
  I := Length(Value);
  inherited Write(I, SizeOf(I));
  if I = 0 then Exit;
  inherited Write(Pointer(Value)^, I);
end;


{ TKMemoryStreamBinary }
function TKMemoryStreamBinary.Write(const Buffer; Count: Longint): Longint;
begin
  Result := inherited Write(Buffer, Count);
end;


procedure TKMemoryStreamBinary.CheckMarker(const aTitle: string);
var
  s: string;
begin
  // We use only Latin for Markers, hence ANSI is fine
  // But since Android does not support "AnsiString" we take "string" as input
  ReadANSI(s);
  Assert(s = aTitle);
end;


procedure TKMemoryStreamBinary.PlaceMarker(const aTitle: string);
begin
  // We use only Latin for Markers, hence ANSI is fine
  // But since Android does not support "AnsiString" we take "string" as input
  WriteANSI(aTitle);
end;


procedure TKMemoryStreamBinary.ReadANSI(out aValue: string);
var
  I: Word;
  bytes: TBytes;
begin
  aValue := '';
  inherited Read(I, SizeOf(I));
  SetLength(bytes, I);
  if I = 0 then Exit;
  inherited Read(bytes[0], I);
  aValue := TEncoding.ANSI.GetString(bytes);
end;


procedure TKMemoryStreamBinary.WriteANSI(const aValue: string);
var
  I: Word;
  bytes: TBytes;
begin
  bytes := TEncoding.ANSI.GetBytes(aValue);
  I := Length(bytes);
  Write(I, SizeOf(I));
  if I = 0 then Exit;
  Write(bytes[0], I);
end;


//{$IFDEF DESKTOP}
procedure TKMemoryStreamBinary.ReadA(out Value: AnsiString);
var I: Word;
begin
  Read(I, SizeOf(I));
  SetLength(Value, I);
  if I > 0 then
    Read(Pointer(Value)^, I);
end;

procedure TKMemoryStreamBinary.WriteA(const Value: AnsiString);
var I: Word;
begin
  I := Length(Value);
  inherited Write(I, SizeOf(I));
  if I = 0 then Exit;
  inherited Write(Pointer(Value)^, I);
end;
//{$ENDIF}


//{$IFDEF TABLET}
//procedure TKMemoryStream.ReadA(out Value: string);
//var I: Word;
//begin
//  Read(I, SizeOf(I));
//  SetLength(Value, I);
//  if I > 0 then
//    Read(Pointer(Value)^, I * SizeOf(WideChar));
//end;
//
//procedure TKMemoryStream.WriteA(const Value: string);
//var I: Word;
//begin
//  I := Length(Value);
//  inherited Write(I, SizeOf(I));
//  if I = 0 then Exit;
//  inherited Write(Pointer(Value)^, I * SizeOf(WideChar));
//end;
//{$ENDIF}


procedure TKMemoryStreamBinary.ReadW(out Value: UnicodeString);
var I: Word;
begin
  Read(I, SizeOf(I));
  SetLength(Value, I);
  if I > 0 then
    Read(Pointer(Value)^, I * SizeOf(WideChar));
end;


procedure TKMemoryStreamBinary.WriteW(const Value: UnicodeString);
var I: Word;
begin
  I := Length(Value);
  inherited Write(I, SizeOf(I));
  if I = 0 then Exit;
  inherited Write(Pointer(Value)^, I * SizeOf(WideChar));
end;

function TKMemoryStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result := inherited Write(Buffer, Count);
end;

procedure TKMemoryStreamBinary.Read(out Value: TKMDirection);   begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: TKMPoint);       begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: TKMPointW);      begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: TKMPointF);      begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: TKMPointDir);    begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: TKMRangeInt);    begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: TKMRangeSingle); begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: TKMRect);        begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: Single);         begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: Extended);       begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: Integer);        begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: Cardinal);       begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: Byte);           begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: Boolean);        begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: Word);           begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: ShortInt);       begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: SmallInt);       begin inherited Read(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Read(out Value: TDateTime);      begin inherited Read(Value, SizeOf(Value)); end;


procedure TKMemoryStreamBinary.Write(const Value: TKMDirection);   begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: TKMPoint);       begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: TKMPointW);      begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: TKMPointF);      begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: TKMPointDir);    begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: TKMRangeInt);    begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: TKMRangeSingle); begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: TKMRect);        begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: Single);         begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: Extended);       begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: Integer);        begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: Cardinal);       begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: Byte);           begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: Boolean);        begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: Word);           begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: ShortInt);       begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: SmallInt);       begin inherited Write(Value, SizeOf(Value)); end;
procedure TKMemoryStreamBinary.Write(const Value: TDateTime);      begin inherited Write(Value, SizeOf(Value)); end;


{ TKMemoryStreamText }
procedure TKMemoryStreamText.WriteText(const aString: string);
var
  I: Word;
  bytes: TBytes;
begin
  bytes := TEncoding.ANSI.GetBytes(aString + ' ');

  I := Length(bytes);
  inherited Write(bytes[0], I);
end;

function TKMemoryStreamText.Write(const Buffer; Count: Longint): Longint;
begin
  if Count = 1 then
    WriteText(IntToHex(PByte(@Buffer)^, 2) + 'h')
  else
  if Count = 2 then
    WriteText(IntToHex(PWord(@Buffer)^, 4) + 'h')
  else
    WriteText(IntToStr(Count) + 'bytes');
  Result := -1;
end;

procedure TKMemoryStreamText.PlaceMarker(const aTitle: string);
begin
  fLastSection := aTitle;
  WriteText(sLineBreak + '[' + aTitle + ']' + sLineBreak);
end;

procedure TKMemoryStreamText.WriteA(const Value: AnsiString);
begin
  WriteText(UnicodeString(Value));
end;

procedure TKMemoryStreamText.WriteANSI(const aValue: string);
begin
  WriteText(aValue);
end;

procedure TKMemoryStreamText.WriteW(const Value: UnicodeString);
begin
  WriteText(Value);
end;

procedure TKMemoryStreamText.Write(const Value: TKMPointDir);
begin
  WriteText(Value.ToString);
end;

procedure TKMemoryStreamText.Write(const Value: TKMRangeInt);
begin
  WriteText(Value.ToString);
end;

procedure TKMemoryStreamText.Write(const Value: TKMRangeSingle);
begin
  WriteText(Value.ToString);
end;

procedure TKMemoryStreamText.Write(const Value: TKMRect);
begin
  WriteText(Value.ToString);
end;

procedure TKMemoryStreamText.Write(const Value: TKMDirection);
begin
  WriteText('Dir' + IntToStr(Ord(Value)));
end;

procedure TKMemoryStreamText.Write(const Value: TKMPoint);
begin
  WriteText(Value.ToString);
end;

procedure TKMemoryStreamText.Write(const Value: TKMPointW);
begin
  WriteText(Value.ToString);
end;

procedure TKMemoryStreamText.Write(const Value: TKMPointF);
begin
  WriteText(Value.ToString);
end;

procedure TKMemoryStreamText.Write(const Value: Boolean);
begin
  WriteText(BoolToStr(Value, True));
end;

procedure TKMemoryStreamText.Write(const Value: Word);
begin
  WriteText(IntToStr(Value));
end;

procedure TKMemoryStreamText.Write(const Value: ShortInt);
begin
  WriteText(IntToStr(Value));
end;

procedure TKMemoryStreamText.Write(const Value: SmallInt);
begin
  WriteText(IntToStr(Value));
end;

procedure TKMemoryStreamText.Write(const Value: Byte);
begin
  WriteText(IntToStr(Value));
end;

procedure TKMemoryStreamText.Write(const Value: Single);
begin
  WriteText(Format('%.5f', [Value]));
end;

procedure TKMemoryStreamText.Write(const Value: Extended);
begin
  WriteText(Format('%.5f', [Value]));
end;

procedure TKMemoryStreamText.Write(const Value: Integer);
begin
  WriteText(IntToStr(Value));
end;

procedure TKMemoryStreamText.Write(const Value: Cardinal);
begin
  WriteText(IntToStr(Value));
end;

procedure TKMemoryStreamText.Write(const Value: TDateTime);
var
  Str: String;
begin
  DateTimeToString(Str, 'dd.mm.yyyy hh:nn:ss.zzz', Value);
  WriteText(Str);
end;



//Not implemented methods 
procedure TKMemoryStreamText.CheckMarker(const aTitle: string);
begin
  raise Exception.Create('MemoryStreamText.CheckMarker is not implemented yet');
end;

procedure TKMemoryStreamText.ReadANSI(out aValue: string); 
begin
  raise Exception.Create('MemoryStreamText.ReadANSI is not implemented yet');
end;

procedure TKMemoryStreamText.ReadA(out Value: AnsiString);
begin
  raise Exception.Create('MemoryStreamText.ReadA is not implemented yet');
end;

procedure TKMemoryStreamText.ReadW(out Value: UnicodeString);
begin
  raise Exception.Create('MemoryStreamText.ReadW is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: TKMDirection);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: TKMPoint);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: TKMPointW);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: TKMPointF);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: TKMPointDir);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: TKMRangeInt);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: TKMRangeSingle);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: TKMRect);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: Single);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: Extended);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: Integer);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: Cardinal);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: Byte);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: Boolean);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: Word);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: ShortInt);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: SmallInt);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;

procedure TKMemoryStreamText.Read(out Value: TDateTime);
begin
  raise Exception.Create('MemoryStreamText.Read is not implemented yet');
end;


end.
