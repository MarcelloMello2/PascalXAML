unit DelphiCodeGenerator;

interface

uses
  System.Classes, System.SysUtils, XamlParser;

type
  TDelphiCodeGenerator = class
  private
    FIndentLevel: Integer;
    FStringBuilder: TStringBuilder;
    
    procedure AppendLine(const ALine: string = '');
    procedure IncreaseIndent;
    procedure DecreaseIndent;
    function GetIndentString: string;
    
    procedure GenerateFormDeclaration(AElement: TXamlElement);
    procedure GenerateComponentDeclarations(AElement: TXamlElement);
    procedure GenerateInitializeComponent(AElement: TXamlElement);
    procedure GenerateComponentCreation(AElement: TXamlElement; AParentName: string = '');
  public
    constructor Create;
    destructor Destroy; override;
    
    function GenerateDelphiCode(AXamlElement: TXamlElement; const AUnitName: string): string;
  end;

implementation

constructor TDelphiCodeGenerator.Create;
begin
  inherited;
  FIndentLevel := 0;
  FStringBuilder := TStringBuilder.Create;
end;

destructor TDelphiCodeGenerator.Destroy;
begin
  FStringBuilder.Free;
  inherited;
end;

procedure TDelphiCodeGenerator.AppendLine(const ALine: string);
begin
  if ALine <> '' then
    FStringBuilder.AppendLine(GetIndentString + ALine)
  else
    FStringBuilder.AppendLine('');
end;

procedure TDelphiCodeGenerator.IncreaseIndent;
begin
  Inc(FIndentLevel);
end;

procedure TDelphiCodeGenerator.DecreaseIndent;
begin
  if FIndentLevel > 0 then
    Dec(FIndentLevel);
end;

function TDelphiCodeGenerator.GetIndentString: string;
begin
  Result := StringOfChar(' ', FIndentLevel * 2);
end;

function TDelphiCodeGenerator.GenerateDelphiCode(AXamlElement: TXamlElement; 
  const AUnitName: string): string;
var
  FormName: string;
begin
  FStringBuilder.Clear;
  
  // Verificar se o elemento raiz é um Form
  if AXamlElement.Name <> 'Form' then
    raise Exception.Create('O elemento raiz deve ser um Form');
    
  // Obter o nome do formulário ou usar um padrão
  if AXamlElement.HasAttribute('Name') then
    FormName := AXamlElement.GetAttribute('Name')
  else
    FormName := 'MainForm';
  
  // Gerar cabeçalho da unit
  AppendLine('unit ' + AUnitName + ';');
  AppendLine;
  AppendLine('interface');
  AppendLine;
  AppendLine('uses');
  AppendLine('  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,');
  AppendLine('  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;');
  AppendLine;
  
  // Gerar declaração do formulário
  GenerateFormDeclaration(AXamlElement);
  
  AppendLine;
  AppendLine('implementation');
  AppendLine;
  AppendLine('{$R *.dfm}');
  AppendLine;
  
  // Gerar método InitializeComponent
  GenerateInitializeComponent(AXamlElement);
  
  AppendLine('end.');
  
  Result := FStringBuilder.ToString;
end;

procedure TDelphiCodeGenerator.GenerateFormDeclaration(AXamlElement: TXamlElement);
var
  FormName: string;
begin
  if AXamlElement.HasAttribute('Name') then
    FormName := AXamlElement.GetAttribute('Name')
  else
    FormName := 'MainForm';
    
  AppendLine('type');
  AppendLine('  T' + FormName + ' = class(TForm)');
  IncreaseIndent;
  
  // Gerar declarações dos componentes
  GenerateComponentDeclarations(AXamlElement);
  
  AppendLine('private');
  AppendLine('  { Private declarations }');
  AppendLine('  procedure InitializeComponent;');
  AppendLine('public');
  AppendLine('  { Public declarations }');
  AppendLine('  constructor Create(AOwner: TComponent); override;');
  DecreaseIndent;
  AppendLine('  end;');
  AppendLine;
  AppendLine('var');
  AppendLine('  ' + FormName + ': T' + FormName + ';');
end;

procedure TDelphiCodeGenerator.GenerateComponentDeclarations(AXamlElement: TXamlElement);
var
  I: Integer;
  Child: TXamlElement;
  CompName: string;
  CompType: string;
begin
  for I := 0 to AXamlElement.Children.Count - 1 do
  begin
    Child := AXamlElement.Children[I];
    
    if Child.HasAttribute('Name') then
    begin
      CompName := Child.GetAttribute('Name');
      CompType := 'T' + Child.Name;
      
      AppendLine(CompName + ': ' + CompType + ';');
    end;
    
    // Processar filhos recursivamente
    GenerateComponentDeclarations(Child);
  end;
end;

procedure TDelphiCodeGenerator.GenerateInitializeComponent(AXamlElement: TXamlElement);
var
  FormName: string;
begin
  if AXamlElement.HasAttribute('Name') then
    FormName := AXamlElement.GetAttribute('Name')
  else
    FormName := 'MainForm';

  AppendLine('constructor T' + FormName + '.Create(AOwner: TComponent);');
  AppendLine('begin');
  IncreaseIndent;
  AppendLine('inherited Create(AOwner);');
  AppendLine('InitializeComponent;');
  DecreaseIndent;
  AppendLine('end;');
  AppendLine;
  
  AppendLine('procedure T' + FormName + '.InitializeComponent;');
  AppendLine('begin');
  IncreaseIndent;
  
  // Configurar propriedades do formulário
  if AXamlElement.HasAttribute('Caption') then
    AppendLine('Self.Caption := ''' + AXamlElement.GetAttribute('Caption') + ''';');
    
  if AXamlElement.HasAttribute('Width') then
    AppendLine('Self.Width := ' + AXamlElement.GetAttribute('Width') + ';');
    
  if AXamlElement.HasAttribute('Height') then
    AppendLine('Self.Height := ' + AXamlElement.GetAttribute('Height') + ';');
  
  // Criar componentes
  GenerateComponentCreation(AXamlElement, 'Self');
  
  DecreaseIndent;
  AppendLine('end;');
end;

procedure TDelphiCodeGenerator.GenerateComponentCreation(AXamlElement: TXamlElement; 
  AParentName: string);
var
  I: Integer;
  Child: TXamlElement;
  CompName: string;
  CompType: string;
  AttrName: string;
  AttrValue: string;
  AttrPair: TPair<string, string>;
begin
  for I := 0 to AXamlElement.Children.Count - 1 do
  begin
    Child := AXamlElement.Children[I];
    
    // Obter nome e tipo do componente
    CompType := 'T' + Child.Name;
    
    if Child.HasAttribute('Name') then
      CompName := Child.GetAttribute('Name')
    else
      CompName := 'Unnamed' + Child.Name + IntToStr(I);
    
    // Criar componente
    AppendLine(CompName + ' := ' + CompType + '.Create(Self);');
    AppendLine(CompName + '.Parent := ' + AParentName + ';');
    
    // Configurar propriedades
    for AttrPair in Child.Attributes do
    begin
      AttrName := AttrPair.Key;
      AttrValue := AttrPair.Value;
      
      // Ignorar o atributo Name pois já foi usado
      if AttrName = 'Name' then
        Continue;
        
      // Configurar propriedade baseado no tipo
      if (AttrName = 'Width') or (AttrName = 'Height') or 
         (AttrName = 'Left') or (AttrName = 'Top') then
        AppendLine(CompName + '.' + AttrName + ' := ' + AttrValue + ';')
      else
        AppendLine(CompName + '.' + AttrName + ' := ''' + AttrValue + ''';');
    end;
    
    // Processar filhos recursivamente
    GenerateComponentCreation(Child, CompName);
  end;
end;

end.