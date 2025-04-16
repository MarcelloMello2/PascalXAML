unit PascalXAML.CodeGenerator;

interface

uses
  System.Classes, System.SysUtils, PascalXAML.Parser;

type
  TPascalXamlCodeGenerator = class
  private
    FIndentLevel: Integer;
    FStringBuilder: TStringBuilder;
    
    procedure AppendLine(const ALine: string = '');
    procedure IncreaseIndent;
    procedure DecreaseIndent;
    function GetIndentString: string;
    
    procedure GenerateFormDeclaration(AElement: TPascalXamlElement);
    procedure GenerateComponentDeclarations(AElement: TPascalXamlElement);
    procedure GenerateInitializeComponent(AElement: TPascalXamlElement);
    procedure GenerateComponentCreation(AElement: TPascalXamlElement; AParentName: string = '');
  public
    constructor Create;
    destructor Destroy; override;
    
    function GenerateDelphiCode(AXamlElement: TPascalXamlElement; const AUnitName: string): string;
  end;

implementation

constructor TPascalXamlCodeGenerator.Create;
begin
  inherited;
  FIndentLevel := 0;
  FStringBuilder := TStringBuilder.Create;
end;

destructor TPascalXamlCodeGenerator.Destroy;
begin
  FStringBuilder.Free;
  inherited;
end;

procedure TPascalXamlCodeGenerator.AppendLine(const ALine: string);
begin
  if ALine <> '' then
    FStringBuilder.AppendLine(GetIndentString + ALine)
  else
    FStringBuilder.AppendLine('');
end;

procedure TPascalXamlCodeGenerator.IncreaseIndent;
begin
  Inc(FIndentLevel);
end;

procedure TPascalXamlCodeGenerator.DecreaseIndent;
begin
  if FIndentLevel > 0 then
    Dec(FIndentLevel);
end;

function TPascalXamlCodeGenerator.GetIndentString: string;
begin
  Result := StringOfChar(' ', FIndentLevel * 2);
end;

function TPascalXamlCodeGenerator.GenerateDelphiCode(AXamlElement: TPascalXamlElement; 
  const AUnitName: string): string;
var
  FormName: string;
begin
  FStringBuilder.Clear;
  
  // Verificar se o elemento raiz é um Form
  if AXamlElement.ComponentClass <> 'TForm' then
    raise Exception.Create('O elemento raiz deve ser um Form');
    
  // Obter o nome do formulário
  FormName := AXamlElement.ComponentName;
  if FormName = '' then
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

procedure TPascalXamlCodeGenerator.GenerateFormDeclaration(AXamlElement: TPascalXamlElement);
var
  FormName: string;
begin
  FormName := AXamlElement.ComponentName;
  if FormName = '' then
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

procedure TPascalXamlCodeGenerator.GenerateComponentDeclarations(AXamlElement: TPascalXamlElement);
var
  I: Integer;
  Child: TPascalXamlElement;
begin
  for I := 0 to AXamlElement.Children.Count - 1 do
  begin
    Child := AXamlElement.Children[I];
    AppendLine(Child.ComponentName + ': ' + Child.ComponentClass + ';');
    
    // Processar filhos recursivamente
    GenerateComponentDeclarations(Child);
  end;
end;

procedure TPascalXamlCodeGenerator.GenerateInitializeComponent(AXamlElement: TPascalXamlElement);
var
  FormName: string;
begin
  FormName := AXamlElement.ComponentName;
  if FormName = '' then
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

procedure TPascalXamlCodeGenerator.GenerateComponentCreation(AXamlElement: TPascalXamlElement; 
  AParentName: string);
var
  I: Integer;
  Child: TPascalXamlElement;
  AttrName: string;
  AttrValue: string;
  AttrPair: TPair<string, string>;
begin
  for I := 0 to AXamlElement.Children.Count - 1 do
  begin
    Child := AXamlElement.Children[I];
    
    // Criar componente
    AppendLine(Child.ComponentName + ' := ' + Child.ComponentClass + '.Create(Self);');
    AppendLine(Child.ComponentName + '.Parent := ' + AParentName + ';');
    
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
        AppendLine(Child.ComponentName + '.' + AttrName + ' := ' + AttrValue + ';')
      else
        AppendLine(Child.ComponentName + '.' + AttrName + ' := ''' + AttrValue + ''';');
    end;
    
    // Processar filhos recursivamente
    GenerateComponentCreation(Child, Child.ComponentName);
  end;
end;

end.