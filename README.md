# PascalXAML

PascalXAML é um projeto open source que visa modernizar o desenvolvimento de interfaces de usuário no ecossistema Object Pascal (Delphi, FreePascal, etc.) através de uma abordagem baseada em XAML, similar ao WPF no mundo .NET.

## Visão Geral

O objetivo do PascalXAML é fornecer uma alternativa moderna aos arquivos DFM do Delphi, permitindo:

- Edição de interfaces diretamente em arquivos de texto (XAML)
- Trabalho em editores modernos como VS Code, Sublime Text, etc.
- Independência da IDE para design visual
- Melhor controle de versão de interfaces
- Potencial suporte a múltiplos compiladores Pascal (Delphi, FreePascal, Oxygene, etc.)

## Estrutura do Projeto

O projeto é composto por vários componentes:

1. **Biblioteca Core**
   - Parser XAML para Object Pascal
   - Mapeamento de tags para componentes Delphi/FPC
   - Gerador de código Object Pascal a partir de XAML

2. **Extensão para VS Code** (em desenvolvimento)
   - Suporte a sintaxe
   - IntelliSense para componentes e propriedades
   - Validação de XAML
   - Snippets comuns

3. **Ferramenta de linha de comando** (planejada)
   - Compilador XAML para código Pascal
   - Integração com processos de build

4. **Biblioteca de componentes** (planejada)
   - Implementações padrão dos componentes visuais
   - Adaptadores para VCL, FMX, LCL (Lazarus)

## Exemplo de XAML

```xml
<Form xmlns="http://pascalxaml.org/ui"
      xmlns:vclcontrols="http://pascalxaml.org/ui/vcl"
      Width="400" Height="300" 
      Caption="Meu Formulário XAML">
  
  <Panel Align="alTop" Height="50">
    <Label Left="10" Top="15" Caption="Nome:"/>
    <Edit Name="edtNome" Left="60" Top="12" Width="200"/>
    <Button Name="btnSalvar" Left="270" Top="10" Width="80" 
            Caption="Salvar" OnClick="btnSalvarClick"/>
  </Panel>
  
  <Memo Align="alClient" ScrollBars="ssBoth"/>
</Form>