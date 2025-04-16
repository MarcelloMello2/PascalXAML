# PascalXAML
A ideia é criar um projeto open source para modernizar a criação de interfaces no ecossistema Delphi/Object Pascal


#### Componentes principais

1. **Biblioteca Core**
   - Parser XAML para Object Pascal
   - Mapeamento de tags para componentes Delphi/FPC
   - Gerador de código Object Pascal a partir de XAML

2. **Extensão para VS Code**
   - Suporte a sintaxe
   - IntelliSense para componentes e propriedades
   - Validação de XAML
   - Snippets comuns

3. **Ferramenta de linha de comando**
   - Compilador XAML para código Pascal
   - Integração com processos de build

4. **Biblioteca de componentes**
   - Implementações padrão dos componentes visuais
   - Adaptadores para VCL, FMX, LCL (Lazarus)

#### Plano de desenvolvimento

1. **MVP (Produto Mínimo Viável)**
   - Suporte básico a contêineres (Form, Panel)
   - Componentes comuns (Button, Edit, Label, etc.)
   - Geração de código para Delphi VCL
   - Extensão básica para VS Code

2. **Expansão**
   - Suporte a mais componentes
   - Bindings de dados
   - Suporte a estilos/temas
   - Suporte a FMX/FireMonkey
   - Suporte a Lazarus/LCL

3. **Ferramenta visual**
   - Editor visual que gera XAML
   - Visualizador de design em tempo real

#### Exemplo de como poderia ser o XAML para Delphi

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
```

### Primeiros passos para o projeto open source

1. **Configurar repositório**
   - GitHub ou GitLab
   - Documentação básica (README, CONTRIBUTING)
   - Licença (MIT, Apache 2.0 ou similar)

2. **Criar estrutura do projeto**
   - Definir arquitetura
   - Estabelecer padrões de código
   - Configurar CI/CD

3. **Implementar prova de conceito**
   - Parser XAML simples
   - Gerador de código para um formulário básico
   - Demonstração de um caso de uso simples

4. **Engajar a comunidade**
   - Anunciar em fóruns de Delphi (Embarcadero, Stack Overflow, grupos do Facebook)
   - Apresentar em eventos de comunidade (se possível)
   - Convidar desenvolvedores para contribuir

### Desafios técnicos a considerar

1. **Namespaces e resolução de tipos**
   - Como lidar com componentes de terceiros
   - Sistema modular para extensões

2. **Diferenças entre compiladores**
   - Garantir compatibilidade com Delphi, FPC, etc.
   - Abstrair diferenças na API de componentes

3. **Eventos e código de comportamento**
   - Como integrar o XAML com código de negócios
   - Implementação de eventos e delegates

4. **Ferramenta de migração**
   - Converter DFMs existentes para XAML
   - Preservar compatibilidade com projetos legados