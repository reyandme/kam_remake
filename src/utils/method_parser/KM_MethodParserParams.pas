unit KM_MethodParserParams;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections;

type
  TKMParamFlag = (pfVar, pfConst, pfOptional, pfNone);

const
  ParamFlagName: array[TKMParamFlag] of string = (
    'var', 'const', 'optional', 'none'
  );

type
  TKMParam = class(TObject)
  public
    ParamName,
    ParamType,
    DefaultValue: string;
    Flag:        TKMParamFlag;
    class function ParamFlagToStr(aFlags: TKMParamFlag): string;
    class function StrToParamFlag(const aValue: string): TKMParamFlag;
    constructor Create;
  end;

  TKMParamList = class(TObjectList<TKMParam>)
  public
    function NewItem: TKMParam;
    function IndexByName(const aParamName: string): Integer; virtual;
  end;

implementation
uses
  SysUtils;

{ TSEParam }
class function TKMParam.ParamFlagToStr(aFlags: TKMParamFlag): string;
begin
  case aFlags of
    pfVar:      Result := 'var';
    pfConst:    Result := 'const';
    pfOptional: Result := 'optional';
    else        Result := 'none';
  end;
end;

class function TKMParam.StrToParamFlag(const aValue: string): TKMParamFlag;
var
  I: TKMParamFlag;
begin
  Result := pfNone;

  for I := Low(TKMParamFlag) to High(TKMParamFlag) do
    if ParamFlagName[I] = aValue then
      Exit(I);
end;

constructor TKMParam.Create;
begin
  inherited;
  ParamName    := 'NewParam';
  ParamType    := 'NewParamType';
  Flag         := pfNone;
  DefaultValue := '';
end;

{ TSEParamList }
function TKMParamList.NewItem: TKMParam;
begin
  Result := TKMParam.Create;
  Add(Result);
end;

function TKMParamList.IndexByName(const aParamName: string): Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to Count - 1 do
    if Items[I].ParamName = aParamName then
      Exit(I);
end;

end.
