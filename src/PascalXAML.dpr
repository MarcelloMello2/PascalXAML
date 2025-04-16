program PascalXAML;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  XamlParser in 'XamlParser.pas',
  DelphiCodeGenerator in 'DelphiCodeGenerator.pas';

var
  XamlParser: TXamlParser;
  CodeGenerator: TDelphiCodeGenerator;
  XamlRoot: TXamlElement;
  XamlContent: string;
  DelphiCode: string;
  OutputFile: TStreamWriter;

begin
  try
    // Exemplo de conteúdo XAML
    XamlContent := 
      '<Form xmlns="http://pascalxaml.org/ui" ' +
      '      xmlns:vcl="http://pascalxaml.org/ui/vcl" ' +
      '      Name="MainForm" ' +
      '      Caption="Exemplo PascalXAML" ' +
      '      Width="500" Height="350">' +
      '  <Panel Name="pnlTop" Align="alTop" Height="50">' +
      '    <Label Name="lblNome" Left="10" Top="15" Caption="Nome:"/>' +
      '    <Edit Name="edtNome" Left="60" Top="12" Width="200"/>' +
      '    <Button Name="btnSalvar" Left="270" Top="10" Width="80" ' +
      '            Caption="Salvar" OnClick="btnSalvarClick"/>' +
      '  </Panel>' +
      '  <Memo Name="memoLog" Align="alClient" ScrollBars="ssBoth"/>' +
      '</Form>';

    // Criar e configurar o parser
    XamlParser := TXamlParser.Create;
    try
      // Analisar o XAML
      WriteLn('Analisando XAML...');
      XamlRoot := XamlParser.Parse(XamlContent);
      
      // Criar o gerador de código
      CodeGenerator := TDelphiCodeGenerator.Create;
      try
        // Gerar o código Delphi
        WriteLn('Gerando código Delphi...');
        DelphiCode := CodeGenerator.GenerateDelphiCode(XamlRoot, 'MainFormUnit');
        
        // Exibir o código gerado
        WriteLn('Código Delphi gerado:');
        WriteLn('--------------------');
        WriteLn(DelphiCode);
        
        // Salvar o código gerado
        WriteLn('Salvando código em MainFormUnit.pas...');
        OutputFile := TStreamWriter.Create('MainFormUnit.pas', False, TEncoding.UTF8);
        try
          OutputFile.Write(DelphiCode);
        finally
          OutputFile.Free;
        end;
        
        WriteLn('Concluído com sucesso!');
      finally
        CodeGenerator.Free;
      end;
    finally
      XamlParser.Free;
    end;
    
    WriteLn('Pressione Enter para sair...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('Erro: ' + E.Message);
      ReadLn;
    end;
  end;
end.