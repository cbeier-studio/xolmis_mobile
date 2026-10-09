# Notas de Versão

Esta seção documenta as mudanças, novos recursos e melhorias introduzidas em cada versão do **Xolmis Mobile**. As notas de versão ajudam os usuários a entender o que foi adicionado, modificado ou planejado para futuras atualizações.

## v1.0.4 (não publicado)

### Novos recursos

- Adicionado campo de modo de locomoção no inventário.  
- Adicionado campo de registro duvidoso no registro da espécie.  
- Indicador de lifer (primeiro registro) na lista de espécies do inventário.  

### Melhorias

- Adicionado link para a ajuda online no app.  
- Modificado layout de arquivos CSV e Excel exportados para melhorar compatibilidade com outros softwares.
- Edição de data, hora e coordenadas de inventários, ninhos e espécimes.  
- Indicador de coordenadas geográficas faltantes.
- Mostra tempo decorrido nos detalhes do inventário.
- Renovado visual das telas de estatísticas.

### Correções

- Diálogo para alterar o número de indivíduos de uma espécie não estava aplicando o valor informado.
- Tela de estatísticas dos inventários selecionados ficava travada no carregamento.
- Compartilhamento de arquivos Excel algumas vezes não funcionava.

## v1.0.3 (2026-09-19)

Beta inicial do Xolmis Mobile.

### Novos recursos

- Vários tipos de inventário, incluindo listas qualitativas, listas temporizadas, listas por intervalos, listas de Mackinnon, anilhamento, transectos, pontos de escuta e métodos baseados em detecção.  
- Gráficos de acumulação de espécies para inventários individuais e inventários selecionados.  
- Módulo Diário de Campo com notas formatadas.  
- Módulo Ninhos com revisões, ovos, imagens e geração automática de número de campo.  
- Módulo Espécimes com categorias pendente/arquivado e anexos de imagens.  
- Entrada de dados de clima e vegetação para inventários.  
- Adicionar e editar notas de espécies, notas de POI e detalhes de inventário.  
- Adicionar nomes de espécies personalizados não encontrados na lista taxonômica.  
- Seleção múltipla para excluir ou exportar inventários, ninhos e espécimes.  
- Filtros para inventários, ninhos, espécimes e entradas do diário de campo.  
- Sugestões de ação quando listas ou telas estão vazias (experimental).  
- Opção para definir o módulo inicial exibido ao abrir o app.  
- Sistema de backup e restauração para todos os dados e imagens.  
- Opções de exportação de inventários, ninhos e espécimes: CSV, Excel (experimental), JSON e KML.
- Opções de exportação de notas do diário de campo: JSON, Texto simples, Markdown e Word.  
- Importação de inventários, ninhos, espécimes e notas a partir de JSON.  
- Abreviação do observador obrigatória e usada para gerar IDs e números de campo.  
- Capacidade de gerar IDs de inventário automaticamente.  

### Melhorias

- Grandes melhorias de desempenho em inventários e ninhos (~90% mais rápido).  
- Telas de estatísticas reformuladas com novos gráficos e métricas.  
- Menus de ordenação, menus de toque longo e barras de busca aprimorados.  
- Destaque de itens selecionados e primeiras ocorrências de espécies em relatórios.  
- Comportamento aprimorado da lista de espécies, incluindo separação dentro/fora da amostra.
- Adição de espécie no inventário com quantidade de indivíduos diretamente na busca.
- Melhor gerenciamento de inventários simultâneos e regras de sincronização.
- Layout aprimorado para telas maiores e tela Sobre refinada com patrocinadores.  
- Melhor formatação de CSV, opções de formatação numérica e precisão de coordenadas. 
- Padronização dos formatos de importação e exportação de JSON para inventários, ninhos e espécimes.
- Lembretes aprimorados para dados ausentes de vegetação ou clima.  
- Pré-carregamento de nomes de espécies na inicialização para busca mais rápida.  
- Mensagens de erro e aviso mais consistentes.  
- Limpeza de arquivos temporários e banco de dados ao iniciar o app.
- Mini gráfico de acumulação de espécies no campo de adição de espécies no inventário.
- Reformulado carregamento de miniaturas de imagens nas listas.
- Atualização da **[taxonomia Clements](https://www.birds.cornell.edu/clementschecklist/)** para v2025, garantindo alinhamento com a classificação ornitológica mais recente.

### Correções

- Diversas correções em cronômetros, incluindo finalizações inesperadas e problemas de reinício.  
- Correções em atualizações, exclusões e sincronização da lista de espécies.  
- Correções em listas de Mackinnon, listas por intervalos e finalização automática.  
- Problemas resolvidos com salvamento de campos, autocompletar e valores nulos.  
- Correções de telas em branco após exclusões e problemas de atualização da interface.  
- Correções no salvamento de localidades, criação de tabela de POI e geração de IDs/números de campo.  
- Correções no salvamento de dados climáticos, verificações de nulos na exportação CSV e ordenação do diário de campo.  
- Melhor tratamento de erros de GPS com opções alternativas.  
- Correções em revisões de ninhos, contagem de ovos e manipulação de espécimes.  
- Diversas correções de interface, incluindo problemas no modo escuro e navegação.
- Tela de configurações agora respeita o tema selecionado (claro/escuro).
- Imagens agora salvam o caminho relativo para evitar problemas de arquivo não encontrado.
- Corrigida inconsistência nos caminhos temporários de exportação e backup.
- Curva de acumulação de espécies agora mostra o acumulado de espécies corretamente.

### Atualizações técnicas

- Atualização do **Flutter** para v3.47 (framework de desenvolvimento).  
- Atualização do **Dart** para v3.13 (linguagem de programação).  
- Migração para novos componentes Flutter (`MenuAnchor`, `SearchAnchor`).  
- Remoção de dependências obsoletas (ex.: `workmanager`, `about`, `geoxml`).  
- Reestruturação interna do código e métodos de operação em segundo plano.  
- Melhorias no gerenciamento do banco de dados, caminhos temporários e consistência de exportação/backup.  
- Adicionado suporte a iOS/iPadOS e comportamento multiplataforma aprimorado.

*[CSV]: Comma Separated Values  
*[JSON]: JavaScript Object Notation  
*[KML]: Keyhole Markup Language  
*[POI]: Point of Interest
