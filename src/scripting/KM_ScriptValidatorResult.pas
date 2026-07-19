unit KM_ScriptValidatorResult;
{$I KaM_Remake.inc}
interface
uses
  SysUtils,
  KM_IoXML;


type
  TKMScriptValidatorIssue = record
    Line: Integer;
    Column: Integer;
    Module: string;
    Param: string;
    Msg: string;
  end;
  TKMScriptValidatorIssueArray = array of TKMScriptValidatorIssue;

  TKMScriptValidatorResult = class(TObject)
  strict private
    fHints: TKMScriptValidatorIssueArray;
    fWarnings: TKMScriptValidatorIssueArray;
    fErrors: TKMScriptValidatorIssueArray;
    procedure Add(aLine, aColumn: Integer; const aParam, aMessage: string; var aDest: TKMScriptValidatorIssueArray); inline;
    procedure ArrayToXML(aSrc: TKMScriptValidatorIssueArray; var aDest: TKMXmlNode);
    procedure XMLToArray(aSrc: TKMXmlNode; var aDest: TKMScriptValidatorIssueArray);
    function FixText(const aTest: string): string;
  public
    procedure AddHint(aLine, aColumn: Integer; const aParam, aMessage: string);
    procedure AddWarning(aLine, aColumn: Integer; const aParam, aMessage: string);
    procedure AddError(aLine, aColumn: Integer; const aParam, aMessage: string);
    function ToXML: string;
    procedure FromXML(const aXml: string);
    property Hints: TKMScriptValidatorIssueArray read fHints write fHints;
    property Warnings: TKMScriptValidatorIssueArray read fWarnings write fWarnings;
    property Errors: TKMScriptValidatorIssueArray read fErrors write fErrors;
  end;

implementation
uses
  Classes;

{ TScriptValidatorResult }
procedure TKMScriptValidatorResult.Add(aLine, aColumn: Integer; const aParam, aMessage: string; var aDest: TKMScriptValidatorIssueArray);
var
  I: Integer;
  Issue: TKMScriptValidatorIssue;
begin
  I := Length(aDest);
  SetLength(aDest, I + 1);
  Issue.Line   := aLine;
  Issue.Column := aColumn;
  Issue.Param  := aParam;
  Issue.Msg    := aMessage;
  aDest[I]     := Issue;
end;


procedure TKMScriptValidatorResult.AddHint(aLine, aColumn: Integer; const aParam, aMessage: string);
begin
  Add(aLine, aColumn, aParam, aMessage, fHints);
end;


procedure TKMScriptValidatorResult.AddWarning(aLine, aColumn: Integer; const aParam, aMessage: string);
begin
  Add(aLine, aColumn, aParam, aMessage, fWarnings);
end;


procedure TKMScriptValidatorResult.AddError(aLine, aColumn: Integer; const aParam, aMessage: string);
begin
  Add(aLine, aColumn, aParam, aMessage, fErrors);
end;


procedure TKMScriptValidatorResult.ArrayToXML(aSrc: TKMScriptValidatorIssueArray; var aDest: TKMXmlNode);
var
  Node:  TKMXmlNode;
  Issue: TKMScriptValidatorIssue;
begin
  for Issue in aSrc do
  begin
    Node := aDest.AddChild('Issue');
    Node.Attributes['Line'] := Issue.Line;
    Node.Attributes['Column'] := Issue.Column;
    Node.Attributes['Module'] := Issue.Module;
    Node.Attributes['Param'] := Issue.Param;
    Node.Attributes['Msg'] := Issue.Msg;
  end;
end;


procedure TKMScriptValidatorResult.XMLToArray(aSrc: TKMXmlNode; var aDest: TKMScriptValidatorIssueArray);
var
  I: Integer;
  Node: TKMXmlNode;
  Issue: TKMScriptValidatorIssue;
  Len: Integer;
begin
  for I := 0 to aSrc.ChildsCount - 1 do
  begin
    Node := aSrc.Childs[I];

    Len := Length(aDest);
    SetLength(aDest, Len + 1);
    Issue.Line   := Node.Attributes['Line'].AsInteger;
    Issue.Column := Node.Attributes['Column'].AsInteger;
    Issue.Module := FixText(Node.Attributes['Module'].AsString);
    Issue.Param  := FixText(Node.Attributes['Param'].AsString);
    Issue.Msg    := FixText(Node.Attributes['Msg'].AsString);
    aDest[Len]   := Issue;
  end;
end;


function TKMScriptValidatorResult.FixText(const aTest: string): string;
begin
  Result := StringReplace(aTest, '&#39;', '"', [rfReplaceAll, rfIgnoreCase]);
end;


function TKMScriptValidatorResult.ToXML: string;
var
  xmlDoc: TKMXmlDocument;
  nHint, nWarning, nError: TKMXmlNode;
begin
  xmlDoc := TKMXmlDocument.Create('ScriptValidatorResult');
  try
    nHint := xmlDoc.Root.AddChild('Hints');
    nWarning := xmlDoc.Root.AddChild('Warnings');
    nError := xmlDoc.Root.AddChild('Errors');

    ArrayToXML(fHints, nHint);
    ArrayToXML(fWarnings, nWarning);
    ArrayToXML(fErrors, nError);

    Result := xmlDoc.Text;
  finally
    xmlDoc.Free;
  end;
end;


procedure TKMScriptValidatorResult.FromXML(const aXml: string);
var
  xmlDoc: TKMXmlDocument;
begin
  xmlDoc := TKMXmlDocument.Create;
  try
    xmlDoc.Text := aXml;
    XMLToArray(xmlDoc.Root.FindNode('Hints'), fHints);
    XMLToArray(xmlDoc.Root.FindNode('Warnings'), fWarnings);
    XMLToArray(xmlDoc.Root.FindNode('Errors'), fErrors);
  finally
    xmlDoc.Free;
  end;
end;


end.
