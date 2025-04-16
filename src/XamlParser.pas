unit XamlParser;

interface

uses
  System.Classes, System.SysUtils, System.Xml.XMLDoc, System.Xml.XMLIntf,
  System.Generics.Collections;

type
  TXamlElement = class
  private
    FName: string;
    FParent: TXamlElement;
    FChildren: TList<TXamlElement>;
    FAttributes: TDictionary<string, string>;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    
    property Name: string read FName;
    property Parent: TXamlElement read FParent write FParent;
    property Children: TList<TXamlElement> read FChildren;
    property Attributes: TDictionary<string, string> read FAttributes;
    
    procedure AddChild(AChild: TXamlElement);
    procedure SetAttribute(const AName, AValue: string);
    function GetAttribute(const AName: string): string;
    function HasAttribute(const AName: string): Boolean;
  end;

  TXamlParser = class
  private
    FRootElement: TXamlElement;
    procedure ProcessNode(ANode: IXMLNode; AParent: TXamlElement);
  public
    constructor Create;
    destructor Destroy; override;
    
    function Parse(const AXamlContent: string): TXamlElement;
    property RootElement: TXamlElement read FRootElement;
  end;

implementation

{ TXamlElement }

constructor TXamlElement.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FChildren := TList<TXamlElement>.Create;
  FAttributes := TDictionary<string, string>.Create;
  FParent := nil;
end;

destructor TXamlElement.Destroy;
var
  I: Integer;
begin
  for I := 0 to FChildren.Count - 1 do
    FChildren[I].Free;
    
  FChildren.Free;
  FAttributes.Free;
  inherited;
end;

procedure TXamlElement.AddChild(AChild: TXamlElement);
begin
  FChildren.Add(AChild);
  AChild.Parent := Self;
end;

procedure TXamlElement.SetAttribute(const AName, AValue: string);
begin
  FAttributes.AddOrSetValue(AName, AValue);
end;

function TXamlElement.GetAttribute(const AName: string): string;
begin
  if not FAttributes.TryGetValue(AName, Result) then
    Result := '';
end;

function TXamlElement.HasAttribute(const AName: string): Boolean;
begin
  Result := FAttributes.ContainsKey(AName);
end;

{ TXamlParser }

constructor TXamlParser.Create;
begin
  inherited;
  FRootElement := nil;
end;

destructor TXamlParser.Destroy;
begin
  if Assigned(FRootElement) then
    FRootElement.Free;
  inherited;
end;

function TXamlParser.Parse(const AXamlContent: string): TXamlElement;
var
  XMLDoc: IXMLDocument;
begin
  // Limpar qualquer elemento raiz anterior
  if Assigned(FRootElement) then
  begin
    FRootElement.Free;
    FRootElement := nil;
  end;

  // Criar e configurar o documento XML
  XMLDoc := TXMLDocument.Create(nil);
  XMLDoc.LoadFromXML(AXamlContent);
  XMLDoc.Active := True;

  // Iniciar o processamento do documento
  FRootElement := TXamlElement.Create(XMLDoc.DocumentElement.NodeName);
  ProcessNode(XMLDoc.DocumentElement, FRootElement);

  Result := FRootElement;
end;

procedure TXamlParser.ProcessNode(ANode: IXMLNode; AParent: TXamlElement);
var
  I: Integer;
  AttrName: string;
  ChildNode: IXMLNode;
  ChildElement: TXamlElement;
begin
  // Processar atributos
  if ANode.HasAttributes then
  begin
    for I := 0 to ANode.AttributeNodes.Count - 1 do
    begin
      AttrName := ANode.AttributeNodes[I].NodeName;
      AParent.SetAttribute(AttrName, ANode.Attributes[AttrName]);
    end;
  end;

  // Processar nós filhos
  for I := 0 to ANode.ChildNodes.Count - 1 do
  begin
    ChildNode := ANode.ChildNodes[I];
    
    // Ignorar nós de texto
    if ChildNode.NodeType = ntText then
      Continue;
      
    ChildElement := TXamlElement.Create(ChildNode.NodeName);
    AParent.AddChild(ChildElement);
    
    // Processar recursivamente
    ProcessNode(ChildNode, ChildElement);
  end;
end;

end.