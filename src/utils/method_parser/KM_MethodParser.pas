unit KM_MethodParser;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections, Classes,
  VerySimpleXML,
  KM_MethodParserParams;

type
  TSEMethodType = (ftFunction, ftProcedure);

const
  MethodTypeName: array[TSEMethodType] of string = (
    'function', 'procedure'
  );

type
  TKMMethod = class(TObject)
  public
    MethodType:     TSEMethodType;
    Params:         TKMParamList;
    MethodName,
    ResultType:     string;
    class function MethodTypeToStr(aType: TSEMethodType): string;
    class function StrToMethodType(const aValue: string): TSEMethodType;
    class function ParseMethodStr(const aValue: string): TKMMethod;
    constructor Create;
    destructor Destroy; override;
    procedure AppendToXML(const aParent: TXmlNode);
    procedure FromXML(const aNode: TXmlNode);
  end;

  TKMMethodList = class(TObjectList<TKMMethod>)
  public
    IsEventList: Boolean;
    constructor Create(aOwnsObjects: Boolean = True); overload;
    function NewItem: TKMMethod;
    function IndexByName(const aMethodName: string): Integer; virtual;
    procedure SaveToFile(const aFileName: string);
    procedure LoadFromFile(const aFileName: string);
    function GenerateMethodInsertNames: TStringList;
    function GenerateMethodItemList: TStringList;
    function GenerateParameterInsertList: TStringList;
    function GenerateParameterLookupList: TStringList;
  end;

implementation
uses
  SysUtils;

{ TSEMethod }
class function TKMMethod.MethodTypeToStr(aType: TSEMethodType): string;
begin
  case aType of
    ftFunction:  Result := 'function';
    ftProcedure: Result := 'procedure';
    else         raise Exception.Create('Unknown value for TFuncType');
  end;
end;

class function TKMMethod.StrToMethodType(const aValue: string): TSEMethodType;
var
  I: TSEMethodType;
begin
  Result := ftProcedure;

  for I := Low(TSEMethodType) to High(TSEMethodType) do
    if MethodTypeName[I] = aValue then
      Exit(I);
end;

class function TKMMethod.ParseMethodStr(const aValue: string): TKMMethod;
var
  param:        TKMParam;
  s,
  paramType,
  defaultValue,
  params:       string;
  paramFlag:    TKMParamFlag;
  paramList,
  parseList:    TStringList;
  I, J,
  splitPos:     Integer;
begin
  s         := aValue;
  paramList := TStringList.Create;
  parseList := TStringList.Create;
  Result    := TKMMethod.Create;

  {
    Case:
    We need to parse the following string to a TSEMethod with it's params:
    'function Example(aId, aAmount: Integer; var aDest: TObjList; aType: TObjType = otSimple): Boolean;'
  }
  // Grab the method type; Expected output: ftFunction
  splitPos := Pos(' ', s);
  Result.MethodType := StrToMethodType(Copy(s, 1, splitPos - 1));
  Delete(s, 1, splitPos);

  if (Pos('(', s) > 0) then
  begin
    // Grab the method name; Expected output: Example
    splitPos := Pos('(', s);
    Result.MethodName := Copy(s, 1, splitPos - 1);
    Delete(s, 1, splitPos);
    // Grab the params; Expected output: aId, aAmount: Integer; var aDest: TObjList; aType: TObjType = otSimple
    splitPos := Pos(')', s);
    params := Copy(s, 1, splitPos - 1);
    Delete(s, 1, splitPos);

    if Result.MethodType = ftFunction then
    begin
      // Grab the result type; Expected output: Boolean
      Delete(s, 1, 1); // Delete ':'
      Result.ResultType := Trim(Copy(s, 1, Pos(';', s) - 1));
    end;

    // Split the parameters into a list
    while params <> '' do
    begin
      splitPos := Pos(';', params);
      s        := Copy(params, 1, splitPos - 1);
      Delete(params, 1, splitPos);
      params := Trim(params);

      if s = '' then
      begin
        s      := params;
        params := '';
      end;

      paramList.Add(s);
    end;

    for I := 0 to paramList.Count - 1 do
    begin
      parseList.Clear;
      paramFlag    := pfNone;
      defaultValue := '';
      paramType    := '';
      s            := Trim(paramList[I]);

      // Grab the param flags; Expected output (In order): pfNone, pfVar, pfOptional
      splitPos := Pos('=', s);

      if splitPos > 0 then
      begin
        // Grab the default values; Expected output: otSimple
        defaultValue := Trim(Copy(s, splitPos + 1, Length(s) - splitPos));
        paramFlag    := pfOptional;
        Delete(s, splitPos, Length(s) - splitPos + 1);
      end;

      if LowerCase(s).StartsWith('var ', True) then
      begin
        paramFlag := pfVar;
        Delete(s, 1, 4);
      end else if LowerCase(s).StartsWith('const ', True) then
      begin
        paramFlag := pfConst;
        Delete(s, 1, 6);
      end;

      // Grab the parameter types; Expected output (In order): Integer, TObjList, TObjType
      splitPos  := Pos(':', s);
      paramType := Trim(Copy(s, splitPos + 1, Length(s) - splitPos));
      Delete(s, splitPos, Length(s) - splitPos + 1);

      // Grab the parameter names; Expected output (In order): [aId, aAmount], [aDest], [aType]
      while s <> '' do
      begin
        s         := Trim(s);
        splitPos  := Pos(',', s);

        if splitPos > 0 then
        begin
          parseList.Add(Trim(Copy(s, 1, splitPos - 1)));
          Delete(s, 1, splitPos);
        end else
        begin
          parseList.Add(s);
          s := '';
        end;
      end;

      // Create param objects and add them to the result
      for J := 0 to parseList.Count - 1 do
      begin
        param              := Result.Params.NewItem;
        param.ParamName    := parseList[J];
        param.ParamType    := paramType;
        param.DefaultValue := defaultValue;
        param.Flag         := paramFlag;
      end;
    end;
  end else
  begin
    // Grab the method name; Expected output: Example
    if Result.MethodType = ftFunction then
    begin
      // Grab the result type; Expected output: Boolean
      splitPos := Pos(':', s);
      Result.MethodName := Copy(s, 1, splitPos - 1);
      Delete(s, 1, splitPos);
      Result.ResultType := Trim(Copy(s, 1, Pos(';', s) - 1));
    end else
    begin
      splitPos := Pos(';', s);
      Result.MethodName := Copy(s, 1, splitPos - 1);
      Delete(s, 1, splitPos);
    end;
  end;

  FreeAndNil(paramList);
  FreeAndNil(parseList);
end;

constructor TKMMethod.Create;
begin
  inherited;
  Params := TKMParamList.Create;
end;

destructor TKMMethod.Destroy;
begin
  FreeAndNil(Params);
  inherited;
end;

procedure TKMMethod.AppendToXML(const aParent: TXmlNode);
var
  item,
  paramParent,
  param:       TXmlNode;
  I:           Integer;
begin
  item := aParent.AddChild('Definition');
  item.SetAttribute('Type', MethodTypeToStr(MethodType));
  item.SetAttribute('Name', MethodName);
  item.SetAttribute('ResultType', ResultType);
  paramParent := item.AddChild('ParameterList');

  for I := 0 to Params.Count - 1 do
  begin
    param := paramParent.AddChild('Parameter');
    param.SetAttribute('Name', Params[I].ParamName);
    param.SetAttribute('Type', Params[I].ParamType);

    if Params[I].DefaultValue <> '' then
      param.SetAttribute('DefaultValue', Params[I].ParamName);

    if Params[I].Flag <> pfNone then
      param.SetAttribute('Flag', TKMParam.ParamFlagToStr(Params[I].Flag));
  end;
end;

procedure TKMMethod.FromXML(const aNode: TXmlNode);
var
  paramParent,
  param:       TXmlNode;
  newItem:     TKMParam;
  I:           Integer;
begin
  MethodType  := StrToMethodType(aNode.Attribute['Type']);
  MethodName  := aNode.Attribute['Name'];
  ResultType  := aNode.Attribute['ResultType'];
  paramParent := aNode.Find('ParameterList');

  for I := 0 to paramParent.ChildNodes.Count - 1 do
  begin
    param                := paramParent.ChildNodes[I];
    newItem              := Params.NewItem;
    newItem.ParamName    := param.Attribute['Name'];
    newItem.ParamType    := param.Attribute['Type'];
    newItem.DefaultValue := param.Attribute['DefaultValue'];
    newItem.Flag         := TKMParam.StrToParamFlag(param.Attribute['Flag']);
  end;
end;

{ TSEMethodList }
constructor TKMMethodList.Create(aOwnsObjects: Boolean = True);
begin
  Inherited Create(aOwnsObjects);
  IsEventList := False;
end;

function TKMMethodList.NewItem: TKMMethod;
begin
  Result := TKMMethod.Create;
  Add(Result);
end;

function TKMMethodList.IndexByName(const aMethodName: string): Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to Count - 1 do
    if Items[I].MethodName = aMethodName then
      Exit(I);
end;

procedure TKMMethodList.SaveToFile(const aFileName: string);
var
  xml: TXmlVerySimple;
  I:   integer;
begin
  xml := TXmlVerySimple.Create;
  xml.Root.NodeName := 'SEMethodDict';

  for I := 0 to Count - 1 do
    Items[I].AppendToXML(xml.Root);

  xml.SaveToFile(aFileName);
end;

procedure TKMMethodList.LoadFromFile(const aFileName: string);
var
  xml:  TXmlVerySimple;
  item: TKMMethod;
  I:    Integer;
begin
  if not FileExists(aFileName) then
    Exit;

  xml := TXmlVerySimple.Create;
  xml.LoadFromFile(aFileName);

  for I := 0 to xml.Root.ChildNodes.Count - 1 do
  begin
    item := NewItem;
    item.FromXML(xml.Root.ChildNodes[I]);
  end;
end;

function TKMMethodList.GenerateMethodInsertNames: TStringList;
const
  EOL              = #13#10;
  DEOL             = #13#10#13#10;
  BEGIN_END_CLAUSE = EOL + 'begin' + DEOL + 'end;'  + EOL;
var
  I, J: Integer;
  s, p: string;
begin
  Result := TStringList.Create;

  for I := 0 to Count - 1 do
  begin
    if IsEventList then
    begin
      s := TKMMethod.MethodTypeToStr(Items[I].MethodType) + ' ' + Items[I].MethodName;

      if Items[I].Params.Count > 0 then
      begin
        p := '';
        s := s + '(';

        for J := 0 to Items[I].Params.Count - 1 do
        begin
          case Items[I].Params.Items[J].Flag of
            pfVar, pfConst: p := p    + TKMParam.ParamFlagToStr(Items[I].Params.Items[J].Flag) +
                                 ' '  + Items[I].Params.Items[J].ParamName +
                                 ': ' + Items[I].Params.Items[J].ParamType;
            pfOptional:     p := p     + TKMParam.ParamFlagToStr(Items[I].Params.Items[J].Flag) +
                                 ' '   + Items[I].Params.Items[J].ParamName +
                                 ': '  + Items[I].Params.Items[J].ParamType +
                                 ' = ' + Items[I].Params.Items[J].DefaultValue;
            pfNone:         p := p     + Items[I].Params.Items[J].ParamName +
                                 ': '  + Items[I].Params.Items[J].ParamType;
          end;

          if J < Items[I].Params.Count - 1 then
            p := p + '; ';
        end;

        s := s + p + ')';
      end;

      Result.Add(s + ';' + BEGIN_END_CLAUSE);
    end else
    begin
      if Items[I].Params.Count > 0 then
        Result.Add(Items[I].MethodName + '(')
      else
        Result.Add(Items[I].MethodName + ';');
    end;
  end;

  Result.Add('');
end;

function TKMMethodList.GenerateMethodItemList: TStringList;
var
  I, J: Integer;
  s, p: string;
begin
  Result := TStringList.Create;

  for I := 0 to Count - 1 do
  begin
    p := '';
    s := TKMMethod.MethodTypeToStr(Items[I].MethodType) + ' \column{}' +
         Items[I].MethodName;

    if Items[I].Params.Count > 0 then
    begin
      s := s + '(';

      for J := 0 to Items[I].Params.Count - 1 do
      begin
        case Items[I].Params.Items[J].Flag of
          pfVar, pfConst: p := p    + TKMParam.ParamFlagToStr(Items[I].Params.Items[J].Flag) +
                               ' '  + Items[I].Params.Items[J].ParamName +
                               ': ' + Items[I].Params.Items[J].ParamType;
          pfOptional:     p := p     + TKMParam.ParamFlagToStr(Items[I].Params.Items[J].Flag) +
                               ' '   + Items[I].Params.Items[J].ParamName +
                               ': '  + Items[I].Params.Items[J].ParamType +
                               ' = ' + Items[I].Params.Items[J].DefaultValue;
          pfNone:         p := p     + Items[I].Params.Items[J].ParamName +
                               ': '  + Items[I].Params.Items[J].ParamType;
        end;

        if J < Items[I].Params.Count - 1 then
          p := p + '; ';
      end;

      s := s + p + ')';
    end;

    case Items[I].MethodType of
      ftFunction:  s := s + ': ' + Items[I].ResultType + ';';
      ftProcedure: s := s + ';';
    end;

    Result.Add(S);
  end;

  Result.Add('');
end;

function TKMMethodList.GenerateParameterInsertList: TStringList;
var
  I, J: Integer;
  s:    string;
begin
  Result := TStringList.Create;

  for I := 0 to Count - 1 do
  begin
    s := '';

    for J := 0 to Items[I].Params.Count - 1 do
    begin
      s := s + '"' + Items[I].Params[J].ParamName + ': ' + Items[I].Params[J].ParamType + '"';

      if J <> Items[I].Params.Count - 1 then
        s := s + ', ';
    end;

    Result.Add(S);
  end;
end;

function TKMMethodList.GenerateParameterLookupList: TStringList;
var
  I: Integer;
begin
  Result := TStringList.Create;

  for I := 0 to Count - 1 do
    Result.Add(UpperCase(Items[i].MethodName));
end;

end.
