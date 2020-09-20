unit KM_IoXML;
interface
uses
  Classes, SysUtils,

  Xml.VerySimple; // (Attributes can be only 'string', which is not convenient)

  // We might try NativeXML (compatible with Android and iOS ?)

  (*
  {$IFDEF TABLET} Xml.omnixmldom, {$ENDIF}
  XMLDoc, XMLIntf; // uses DecimalSeparator which we do not control
  // Android requires to have a compatible XML "DOM Vendor", documentation suggests to use OmniXML
  *)

type
  TXMLDocument = TXmlVerySimple;
  TXMLNode = Xml.VerySimple.TXmlNode;
  TXMLAttribute = Xml.VerySimple.TXmlAttribute;

  //TXMLDocument = XMLIntf.IXMLDocument;
  //TXMLNode = XMLIntf.IXMLNode;

  TKMXMLDocument = class
  private
    fDocument: TXMLDocument;
    fRoot: TXMLNode;
  public
    constructor Create;
    destructor Destroy; override;

    property Root: TXMLNode read fRoot;

    procedure LoadFromFile(const aFilename: string; aReadOnly: Boolean = True);
    procedure SaveToFile(const aFilename: string; aCompressed: Boolean = False);
  end;


implementation


{ TKMXMLDocument }
constructor TKMXMLDocument.Create;
begin
  inherited;

  fDocument := TXMLDocument.Create;

  //fDocument := XMLDoc.TXMLDocument.Create(nil);
  //fDocument.Active := True;
  fDocument.Version := '1.0';
  fDocument.Encoding := 'UTF-8';
  fDocument.Options := [doNodeAutoIndent]; // Do not write BOM

  fRoot := fDocument.AddChild('Root');
end;


destructor TKMXMLDocument.Destroy;
begin
  fDocument.Free;

  //fDocument.Active := False;

  inherited;
end;


procedure TKMXMLDocument.LoadFromFile(const aFilename: string; aReadOnly: Boolean = True);
begin
  // When no file exists we create an empty XML and let caller handle it
  // e.g. by reading default values from it
  if FileExists(aFilename) then
  begin
    try
      fDocument.LoadFromFile(aFilename, 4096, True);
    except on EEncodingError do
      // Encoding error create back up, clear file and we try again
      fDocument.LoadFromFile(aFilename, 4096, False);
    end;
  end;

  fRoot := fDocument.ChildNodes.FindNode('Root');

  // Create root if it's missing, so that XML could be processed and default parameters created
  if fRoot = nil then
    fRoot := fDocument.ChildNodes.Add('Root');
end;


procedure TKMXMLDocument.SaveToFile(const aFilename: string; aCompressed: Boolean = False);
begin
  ForceDirectories(ExtractFilePath(ExpandFileName(aFilename)));

  fDocument.SaveToFile(aFilename);
end;


end.
