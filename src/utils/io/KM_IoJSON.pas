unit KM_IoJSON;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF WDC}
  JsonDataObjects,
  {$ENDIF}
  {$IFDEF FPC}
  fpjson, jsonparser,
  {$ENDIF}
  KM_CommonClasses;

type
  TKMJsonObject = class;
//  TKMJsonObject = TJsonObject;
  TKMJsonArray = class;

  TKMJsonDocument = class
  private
    fRoot: TKMJsonObject;
//    function GetArray(const Name: string): TJsonArray;
  public
    destructor Destroy; override;

    property Root: TKMJsonObject read fRoot;

    procedure LoadFromFile(const aFilename: string);
    procedure SaveToFile(const aFilename: string; aCompact: Boolean = False);
    procedure SaveToStream(aSaveStream: TKMemoryStream; aCompact: Boolean = False);
  end;

  TKMJsonObject = class
  private
    fJsonObject: TJsonObject;

    function GetArray(const Name: string): TKMJsonArray;
    function GetBool(const Name: string): Boolean;
    function GetInt(const Name: string): Integer;
    function GetObject(const Name: string): TKMJsonObject;
    function GetString(const Name: string): string;
    procedure SetArray(const Name: string; const Value: TKMJsonArray);
    procedure SetBool(const Name: string; const Value: Boolean);
    procedure SetInt(const Name: string; const Value: Integer);
    procedure SetObject(const Name: string; const Value: TKMJsonObject);
    procedure SetString(const Name, Value: string);
  public
    constructor Create(aJsonObject: TJsonObject);

    property JsonObject: TJsonObject read fJsonObject;

    function Contains(const Name: string): Boolean;

    // Short names
    property S[const Name: string]: string read GetString write SetString;        // returns '' if property doesn't exist, auto type-cast except for array/object
    property I[const Name: string]: Integer read GetInt write SetInt;             // returns 0 if property doesn't exist, auto type-cast except for array/object
//    property L[const Name: string]: Int64 read GetLong write SetLong;             // returns 0 if property doesn't exist, auto type-cast except for array/object
//    property U[const Name: string]: UInt64 read GetULong write SetULong;          // returns 0 if property doesn't exist, auto type-cast except for array/object
//    property F[const Name: string]: Double read GetFloat write SetFloat;          // returns 0 if property doesn't exist, auto type-cast except for array/object
//    property D[const Name: string]: TDateTime read GetDateTime write SetDateTime; // returns 0 if property doesn't exist, auto type-cast except for array/object
//    property DUtc[const Name: string]: TDateTime read GetUtcDateTime write SetUtcDateTime; // returns 0 if property doesn't exist, auto type-cast except for array/object
    property B[const Name: string]: Boolean read GetBool write SetBool;           // returns false if property doesn't exist, auto type-cast with "<>'true'" and "<>0" except for array/object
    property A[const Name: string]: TKMJsonArray read GetArray write SetArray;      // auto creates array on first access
    property O[const Name: string]: TKMJsonObject read GetObject write SetObject;   // auto creates object on first access


    procedure SaveToStream(aSaveStream: TKMemoryStream; aCompact: Boolean);
    procedure SaveToFile(const aFilename: string; aCompact: Boolean);
  end;


  TKMJsonArray = class
    private
      fJsonArray: TJsonArray;
      function GetArray(Index: Integer): TKMJsonArray;
      function GetBool(Index: Integer): Boolean;
      function GetInt(Index: Integer): Integer;
      function GetObject(Index: Integer): TKMJsonObject;
      function GetString(Index: Integer): string;
      procedure SetArray(Index: Integer; const Value: TKMJsonArray);
      procedure SetBool(Index: Integer; const Value: Boolean);
      procedure SetInt(Index: Integer; const Value: Integer);
      procedure SetObject(Index: Integer; const Value: TKMJsonObject);
      procedure SetString(Index: Integer; const Value: string);
      function GetCount: Integer;
    public
      constructor Create(aJsonArray: TJsonArray);

      property JsonArray: TJsonArray read fJsonArray;

      property Count: Integer read GetCount;

      property S[Index: Integer]: string read GetString write SetString;
      property I[Index: Integer]: Integer read GetInt write SetInt;
//      property L[Index: Integer]: Int64 read GetLong write SetLong;
//      property U[Index: Integer]: UInt64 read GetULong write SetULong;
//      property F[Index: Integer]: Double read GetFloat write SetFloat;
//      property D[Index: Integer]: TDateTime read GetDateTime write SetDateTime;
//      property DUtc[Index: Integer]: TDateTime read GetUtcDateTime write SetUtcDateTime;
      property B[Index: Integer]: Boolean read GetBool write SetBool;
      property A[Index: Integer]: TKMJsonArray read GetArray write SetArray;
      property O[Index: Integer]: TKMJsonObject read GetObject write SetObject;
//      property V[Index: Integer]: Variant read GetVariant write SetVariant;
  end;

//  TKMJsonArray = class
//  private
//    fArray: TJsonArray;
//
//
//  end;


implementation
uses
  Classes, SysUtils
  {$IFDEF FPC}
  , jsonscanner
  {$ENDIF};


{ TKMJsonDocument }
destructor TKMJsonDocument.Destroy;
begin
  FreeAndNil(fRoot);

  inherited;
end;


procedure TKMJsonDocument.LoadFromFile(const aFilename: string);
{$IFDEF FPC}
var
  S : TFileStream;
  P : TJSONParser;
{$ENDIF}
begin
  {$IFDEF WDC}
  FreeAndNil(fRoot);

  fRoot := TKMJsonObject.Create(TJsonObject.ParseFromFile(aFilename) as TJsonObject);
  {$ENDIF}

  {$IFDEF FPC}
  S := TFileStream.Create(aFilename, fmOpenRead or fmShareDenyWrite);
  try
{$IFDEF FPC_FULLVERSION >= 30002}
    P := TJSONParser.Create(S,[]);
{$ELSE}
    P := TJSONParser.Create(S);
{$ENDIF}
    try
{$IFDEF FPC_FULLVERSION >= 30002}
      P.Options := P.Options + [joStrict];
{$ENDIF}
      fRoot := TKMJsonObject.Create(P.Parse as TJsonObject);
    finally
      P.Free;
    end;
  finally
    S.Free;
  end;
  {$ENDIF}
end;


procedure TKMJsonDocument.SaveToFile(const aFilename: string; aCompact: Boolean = False);
begin
  fRoot.SaveToFile(aFilename, aCompact);
end;


procedure TKMJsonDocument.SaveToStream(aSaveStream: TKMemoryStream; aCompact: Boolean = False);
begin
  fRoot.SaveToStream(aSaveStream, aCompact);
end;


//{ TKMJsonArray }
//function TKMJsonArray.GetArray(const Name: string): TJsonArray;
//begin
////  Result := Arrays
//end;


{ TKMJsonObjectHolder }
constructor TKMJsonObject.Create(aJsonObject: TJsonObject);
begin
  inherited Create;

  fJsonObject := aJsonObject;
end;


function TKMJsonObject.Contains(const Name: string): Boolean;
  {$IFDEF FPC}
var
  jData: TJsonData;
  {$ENDIF}
begin
  {$IFDEF WDC}
  Result := fJsonObject.Contains(Name);
  {$ENDIF}
  {$IFDEF FPC}
  Result := fJsonObject.Find(Name, jData);
  {$ENDIF}
end;


function TKMJsonObject.GetArray(const Name: string): TKMJsonArray;
begin
  {$IFDEF WDC}
  Result := TKMJsonArray.Create(fJsonObject.A[Name]);
  {$ENDIF}
  {$IFDEF FPC}
  Result := TKMJsonArray.Create(fJsonObject.Arrays[Name]);
  {$ENDIF}
end;


function TKMJsonObject.GetBool(const Name: string): Boolean;
begin
  {$IFDEF WDC}
  Result := fJsonObject.B[Name];
  {$ENDIF}
  {$IFDEF FPC}
  Result := fJsonObject.Get(Name, False);
  {$ENDIF}
end;


function TKMJsonObject.GetInt(const Name: string): Integer;
begin
  {$IFDEF WDC}
  Result := fJsonObject.I[Name];
  {$ENDIF}
  {$IFDEF FPC}
  Result := fJsonObject.Get(Name, 0);
  {$ENDIF}
end;


function TKMJsonObject.GetObject(const Name: string): TKMJsonObject;
begin
  {$IFDEF WDC}
  Result := TKMJsonObject.Create(fJsonObject.O[Name]);
  {$ENDIF}
  {$IFDEF FPC}
  Result := TKMJsonObject.Create(fJsonObject.Objects[Name]);
  {$ENDIF}
end;


function TKMJsonObject.GetString(const Name: string): string;
begin
  {$IFDEF WDC}
  Result := fJsonObject.S[Name];
  {$ENDIF}
  {$IFDEF FPC}
  Result := fJsonObject.Get(Name, '');
  {$ENDIF}
end;


procedure TKMJsonObject.SetArray(const Name: string; const Value: TKMJsonArray);
begin

end;


procedure TKMJsonObject.SetBool(const Name: string; const Value: Boolean);
begin

end;


procedure TKMJsonObject.SetInt(const Name: string; const Value: Integer);
begin

end;


procedure TKMJsonObject.SetObject(const Name: string; const Value: TKMJsonObject);
begin

end;


procedure TKMJsonObject.SetString(const Name, Value: string);
begin

end;


procedure TKMJsonObject.SaveToFile(const aFilename: string; aCompact: Boolean);
begin
{$IFDEF WDC}
  fJsonObject.SaveToFile(aFilename, aCompact, TEncoding.UTF8)
{$ENDIF}
end;


procedure TKMJsonObject.SaveToStream(aSaveStream: TKMemoryStream; aCompact: Boolean);
begin
{$IFDEF WDC}
  fJsonObject.SaveToStream(aSaveStream, aCompact, TEncoding.UTF8);
{$ENDIF}
end;


{ TKMJsonArray }
constructor TKMJsonArray.Create(aJsonArray: TJsonArray);
begin
  inherited Create;

  fJsonArray := aJsonArray;
end;


function TKMJsonArray.GetCount: Integer;
begin
  {$IFDEF WDC}
  Result := fJsonArray.Count;
  {$ENDIF}
  {$IFDEF FPC}
  Result := fJsonArray.Count;
  {$ENDIF}
end;


function TKMJsonArray.GetArray(Index: Integer): TKMJsonArray;
begin
  {$IFDEF WDC}
  Result := TKMJsonArray.Create(fJsonArray.A[Index]);
  {$ENDIF}
  {$IFDEF FPC}
  Result := TKMJsonArray.Create(fJsonArray.Arrays[Index]);
  {$ENDIF}
end;


function TKMJsonArray.GetBool(Index: Integer): Boolean;
begin
  {$IFDEF WDC}
  Result := fJsonArray.B[Index];
  {$ENDIF}
  {$IFDEF FPC}
  Result := fJsonArray.Booleans[Index];
  {$ENDIF}
end;


function TKMJsonArray.GetInt(Index: Integer): Integer;
begin
  {$IFDEF WDC}
  Result := fJsonArray.I[Index];
  {$ENDIF}
  {$IFDEF FPC}
  Result := fJsonArray.Integers[Index];
  {$ENDIF}
end;


function TKMJsonArray.GetObject(Index: Integer): TKMJsonObject;
begin
  {$IFDEF WDC}
  Result := TKMJsonObject.Create(fJsonArray.O[Index]);
  {$ENDIF}
  {$IFDEF FPC}
  Result := TKMJsonObject.Create(fJsonArray.Objects[Index]);
  {$ENDIF}
end;


function TKMJsonArray.GetString(Index: Integer): string;
begin
  {$IFDEF WDC}
  Result := fJsonArray.S[Index];
  {$ENDIF}
  {$IFDEF FPC}
  Result := fJsonArray.Strings[Index];
  {$ENDIF}
end;


procedure TKMJsonArray.SetArray(Index: Integer; const Value: TKMJsonArray);
begin

end;


procedure TKMJsonArray.SetBool(Index: Integer; const Value: Boolean);
begin

end;


procedure TKMJsonArray.SetInt(Index: Integer; const Value: Integer);
begin

end;


procedure TKMJsonArray.SetObject(Index: Integer; const Value: TKMJsonObject);
begin

end;


procedure TKMJsonArray.SetString(Index: Integer; const Value: string);
begin

end;


end.

