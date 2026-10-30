unit KM_StreamWriter;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils;


type
  TKMStreamWriter = class
  private
    fStream: TFileStream;
  public
    constructor Create(const aPath: UnicodeString);
    destructor Destroy; override;
    procedure Write(const aText: string);
    procedure WriteLine(const aText: string = '');
  end;
  TStreamWriter = TKMStreamWriter;


implementation


constructor TKMStreamWriter.Create(const aPath: UnicodeString);
begin
  inherited Create;

  fStream := TFileStream.Create(UTF8Encode(aPath), fmCreate);
end;


destructor TKMStreamWriter.Destroy;
begin
  FreeAndNil(fStream);

  inherited;
end;


procedure TKMStreamWriter.Write(const aText: string);
begin
  if aText <> '' then
    fStream.WriteBuffer(aText[1], Length(aText));
end;


procedure TKMStreamWriter.WriteLine(const aText: string);
begin
  Write(aText + sLineBreak);
end;


end.
