unit PascalXAML.Parser;

interface

uses
  System.Classes, System.SysUtils, System.Xml.XMLDoc, System.Xml.XMLIntf,
  System.Generics.Collections;

type
  TPascalXamlNamespace = class
  private
    FPrefix: string;
    FUri: string;
  public
    constructor Create(const APrefix, AUri: string);
    property Prefix: string read FPrefix;
    property Uri: string read FUri;
  end;

  TPascalXamlElement = class
  private
    FName: string;
    FParent: TPascalXamlElement;
    FChildren: TList<TPascalXamlElement>;
    FAttributes: TDictionary<string, string>;
    FNamespaces: TList<TPascalXamlNamespace>;
    FContent: string;
    FComponentClass: string;
    FComponentName: string;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    
    property Name: string read FName;
    property Parent: TPascalXamlElement read FParent write FParent;
    property Children: TList<TPascalXamlElement> read FChildren;
    property Attributes: TDictionary<string, string> read FAttributes;
    property Namespaces: TList<TPascalXamlNamespace> read FNamespaces;
    property Content: string read FContent write FContent;
    property ComponentClass: string read FComponentClass write FComponentClass;
    property ComponentName: string read FComponentName write FComponentName;
    
    procedure AddChild(AChild: TPascalXamlElement);
    procedure AddNamespace(const APrefix, AUri: string);
    procedure SetAttribute(const AName, AValue: string);
    function GetAttribute(const AName: string): string;
    function HasAttribute(const AName: string): Boolean;
    function FindNamespaceByPrefix(const APrefix: string): TPascalXamlNamespace;
  end;

  TPascalXamlParser = class
  private
    FRootElement: TPascalXamlElement;
    FNamespaceMap: TDictionary<string, string>; // Maps namespace URI to component prefix
    
    procedure ProcessNode(ANode: IXMLNode; AParent: TPascalXamlElement);
    procedure ResolveComponentClasses(AElement: TPascalXamlElement);
  public
    constructor Create;
    destructor Destroy; override;
    
    function Parse(const AXamlContent: string): TPascalXamlElement;
    procedure RegisterNamespace(const AUri, AComponentPrefix: string);
    property RootElement: TPascalXamlElement read FRootElement;
  end;

implementation

{ TPascalXamlNamespace }

constructor TPascalXamlNamespace.Create(const APrefix, AUri: string);
begin
  inherited Create;
  FPrefix := APrefix;
  FUri := AUri;
end;

{ TPascalXamlElement }

constructor TPascalXamlElement.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FChildren := TList<TPascalXamlElement>.Create;
  FAttributes := TDictionary<string, string>.Create;
  FNamespaces := TList<TPascalXamlNamespace>.Create;
  FParent := nil;
  FContent := '';
  FComponentClass := '';
  FComponentName := '';
end;

destructor TPascalXamlElement.Destroy;
var
  I: Integer;
begin
  for I := 0 to FChildren.Count - 1 do
    FChildren[I].Free;
    
  for I := 0 to FNamespaces.Count - 1 do
    FNamespaces[I].Free;
    
  FChildren.Free;
  FAttributes.Free;
  FNamespaces.Free;
  inherited;
end;

procedure TPascalXamlElement.AddChild(AChild: TPascalXamlElement);
begin
  FChildren.Add(AChild);
  AChild.Parent := Self;
end;

procedure TPascalXamlElement.AddNamespace(const APrefix, AUri: string);
begin
  FNamespaces.Add(TPascalXamlNamespace.Create(APrefix, AUri));
end;

procedure TPascalXamlElement.SetAttribute(const AName, AValue: string);
begin
  FAttributes.AddOrSetValue(AName, AValue);
end;

function TPascalXamlElement.GetAttribute(const AName: string): string;
begin
  if not FAttributes.TryGetValue(AName, Result) then
    Result := '';
end;

function TPascalXamlElement.HasAttribute(const AName: string): Boolean;
begin
  Result := FAttributes.ContainsKey(AName);
end;

function TPascalXamlElement.FindNamespaceByPrefix(const APrefix: string): TPascalXamlNamespace;
var
  I: Integer;
begin
  Result := nil;
  
  for I := 0 to FNamespaces.Count - 1 do
    if FNamespaces[I].Prefix = APrefix then
    begin
      Result := FNamespaces[I];
      Break;
    end;
    
  if (Result = nil) and (Parent <> nil) then
    Result := Parent.FindNamespaceByPrefix(APrefix);
end;

{ TPascalXamlParser }

constructor TPascalXamlParser.Create;
begin
  inherited;
  FRootElement := nil;
  FNamespaceMap := TDictionary<string, string>.Create;
  
  // Register default namespaces
  RegisterNamespace('http://pascalxaml.org/ui', 'T');
  RegisterNamespace('http://pascalxaml.org/ui/vcl', 'T');
  RegisterNamespace('http://pascalxaml.org/ui/fmx', 'T');
end;

destructor TPascalXamlParser.Destroy;
begin
  if Assigned(FRootElement) then
    FRootElement.Free;
  FNamespaceMap.Free;
  inherited;
end;

procedure TPascalXamlParser.RegisterNamespace(const AUri, AComponentPrefix: string);
begin
  FNamespaceMap.AddOrSetValue(AUri, AComponentPrefix);
end;

function TPascalXamlParser.Parse(const AXamlContent: string): TPascalXamlElement;
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
  FRootElement := TPascalXamlElement.Create(XMLDoc.DocumentElement.NodeName);
  ProcessNode(XMLDoc.DocumentElement, FRootElement);
  
  // Resolver classes de componentes
  ResolveComponentClasses(FRootElement);

  Result := FRootElement;
end;

procedure TPascalXamlParser.ProcessNode(ANode: IXMLNode; AParent: TPascalXamlElement);
var
  I: Integer;
  AttrName, AttrValue, NsPrefix, NsUri: string;
  ChildNode: IXMLNode;
  ChildElement: TPascalXamlElement;
  HasXmlns: Boolean;
begin
  // Processar namespaces
  HasXmlns := False;
  if ANode.HasAttributes then
  begin
    for I := 0 to ANode.AttributeNodes.Count - 1 do
    begin
      AttrName := ANode.AttributeNodes[I].NodeName;
      AttrValue := ANode.Attributes[AttrName];
      
      if (AttrName = 'xmlns') then
      begin
        AParent.AddNamespace('', AttrValue);
        HasXmlns := True;
      end
      else if (Copy(AttrName, 1, 6) = 'xmlns:') then
      begin
        NsPrefix := Copy(AttrName, 7, Length(AttrName) - 6);
        AParent.AddNamespace(NsPrefix, AttrValue);
        HasXmlns := True;
      end
      else
        AParent.SetAttribute(AttrName, AttrValue);
    end;
  end;
  
  // Processar texto do nó
  if ANode.IsTextElement then
    AParent.Content := ANode.Text;

  // Processar nós filhos
  for I := 0 to ANode.ChildNodes.Count - 1 do
  begin
    ChildNode := ANode.ChildNodes[I];
    
    // Ignorar nós de texto
    if ChildNode.NodeType = ntText then
      Continue;
      
    ChildElement := TPascalXamlElement.Create(ChildNode.NodeName);
    AParent.AddChild(ChildElement);
    
    // Processar recursivamente
    ProcessNode(ChildNode, ChildElement);
  end;
end;

procedure TPascalXamlParser.ResolveComponentClasses(AElement: TPascalXamlElement);
var
  I: Integer;
  ElementName, NsPrefix, ComponentPrefix, ComponentName: string;
  NsParts: TArray<string>;
  Namespace: TPascalXamlNamespace;
begin
  // Determinar o prefixo do namespace
  ElementName := AElement.Name;
  NsPrefix := '';
  
  NsParts := ElementName.Split([':']);
  if Length(NsParts) > 1 then
  begin
    NsPrefix := NsParts[0];
    ElementName := NsParts[1];
  end;
  
  // Encontrar o namespace
  Namespace := AElement.FindNamespaceByPrefix(NsPrefix);
  
  // Determinar a classe do componente
  if Assigned(Namespace) and FNamespaceMap.TryGetValue(Namespace.Uri, ComponentPrefix) then
    AElement.ComponentClass := ComponentPrefix + ElementName
  else
    AElement.ComponentClass := 'T' + ElementName;
  
  // Determinar o nome do componente
  if AElement.HasAttribute('Name') then
    AElement.ComponentName := AElement.GetAttribute('Name')
  else
    AElement.ComponentName := 'Auto' + ElementName + IntToStr(Random(10000));
  
  // Processar filhos recursivamente
  for I := 0 to AElement.Children.Count - 1 do
    ResolveComponentClasses(AElement.Children[I]);
end;

end.