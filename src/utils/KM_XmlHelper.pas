unit KM_XmlHelper;
{$I KaM_Remake.inc}
interface
uses
  KM_IoXML;


type
  TXMLNodeHelper = class helper for TXMLNode
    function AddOrFindChild(const aChildNodeName: string): TXMLNode;
  end;

implementation
uses
  Classes, SysUtils;


{ TXMLNodeHelper }
function TXMLNodeHelper.AddOrFindChild(const aChildNodeName: string): TXMLNode;
begin
  if not HasChild(aChildNodeName) then
    Result := AddChild(aChildNodeName)
  else
    Result := ChildNodes.FindNode(aChildNodeName);
end;


end.
