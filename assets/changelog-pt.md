# Log de alterações

## 1.0.3

### Novas funcionalidades

* Adicionadas sugestões de ações quando uma lista estiver vazia.
* Adicionadas sugestões de ações na tela de detalhes do inventário e do ninho (experimental).
* Adicionado campo Observador nos inventários, ninhos, espécimes e diário de campo.
* Adicionados filtros para inventários, ninhos, espécimes e diário de campo.

### Melhorias

* Telas de estatísticas refatoradas e expandidas.
* Padronização das mensagens de erro e avisos.

### Correções

* Corrigida tela que ficava vazia após apagar um item.
* Corrigidas listas de Mackinnon não finalizando corretamente.
* Corrigido problema que não salvava o valor informado em campos com autocompletar.

## 1.0.2

### Novas funcionalidades

* Novos tipos de inventários: transecto e ponto de detecções.
* Diário de campo.
* Seção de estatísticas.
* Backup e restauração de dados.
* Exportar para arquivo Excel (experimental).
* Exportar POIs de inventário para arquivo KML (experimental).
* Adicionar e editar detalhes de um inventário.
* Definir um inventário como descartado (experimental).
* Adicionar e editar observações dos POIs das espécies.
* Importar inventários, ninhos ou espécimes de arquivo JSON.
* Adicionar coordenadas da localização atual no texto de uma nota do diário de campo.
* Relatório para comparar espécies entre listas.
* Gráfico de acumulação de espécies nos detalhes do inventário.
* Gráfico de acumulação de espécies para inventários selecionados.
* Gráfico comparando número de espécies entre inventários selecionados.
* Agora o usuário pode selecionar o país da busca de espécies (Argentina, Brasil, Paraguai e Uruguai disponíveis, mais países em breve).

### Melhorias

* Espécimes separados em categorias: pendentes e arquivados.
* Configuração para desativar formatação de números ao exportar arquivos CSV.
* Lembretes configuráveis para adicionar vegetação e/ou dados do tempo quando encerrar um inventário.
* Menus de ordenação refatorados e melhorados.
* Menus de pressionamento longo refatorados para acomodar mais opções.
* Agora a contagem de espécies de inventários separa registros dentro e fora da amostra.
* Curva de acumulação de espécies para inventários selecionados agora mostra duas linhas: acumulado de todas espécies e apenas as espécies dentro da amostra.
* Ícone de exportação foi substituído para melhor refletir sua função.
* Define para 1 a contagem inicial de indivíduos quando a espécie é adicionada a um inventário quantitativo.
* Não permite inativar um ninho sem revisões.
* Não permite adicionar inventários, ninhos, ou espécimes sem definir a abreviatura do observador nas configurações.
* Melhorias no layout em telas maiores.
* Adicionado botão para atualizar as listas de inventários, ninhos e espécimes se estiverem vazias.
* Tela com informações sobre o app reformulada, com adição dos patrocinadores.
* Barra de pesquisa movida para o cabeçalho da tela.
* Atualiza nomes de espécies para taxonomia de Clements/eBird versão 2025.

### Técnico/Dependências

* Suporte ao iOS e iPadOS.
* Atualizado para Flutter 3.38 e Dart 3.10.
* Migrados `PopupMenuButton` e `showMenu` para `MenuAnchor`.
* Substituído `showSearch` por `SearchAnchor`.
* Removida dependência de `workmanager`.

### Correções

* Corrigido problema que encerrava inventários temporizados inesperadamente.
* A lista de espécies de um inventário não atualizava adequadamente depois de adicionar ou remover uma espécie.
* Os campos numéricos agora aceitam apenas os dígitos esperados e separador decimal.
* Melhor formatação dos arquivos CSV exportados.
* Precisão aumentada das coordenadas nos arquivos CSV exportados.
* Melhorado tratamento de erros obtendo a localização atual do GPS do dispositivo, dando opções para entrar manualmente ou apenas ignorar.
* Melhorada verificação de nulos na exportação para CSV.
* Corrigido problema que poderia evitar que dados do tempo fossem salvos.
* Corrigida ordenação da lista do diário de campo.
* A localidade do inventário agora é salva corretamente.
* Corrigida importação de inventário quando o campo descartado é nulo.
* Corrigida edição da ID do inventário.

## 1.0.1

### Novas funcionalidades

* Novo tipo de inventário: lista qualitativa por intervalos.
* Adicionada opção para editar observações da espécie.
* Agora é possível editar registros.
* Adicionadas opções de ordenação das listas de inventários, ninhos e espécimes.
* Seleção múltipla de inventários, ninhos e espécimes para exportar ou apagar.
* Adicionadas barras de pesquisa para inventários, ninhos e espécimes.
* Anexar imagens da galeria ou da câmera para registros de vegetação, revisão de ninho, ovo e espécime.
* Toque/clique na contagem de indivíduos para editar o valor na lista de espécies.
* Adicionada opção para inserir espécie não encontrada na lista de sugestões de espécies.
* Adicionada abreviatura do observador nas configurações e agora ninhos, ovos e espécimes geram números de campo.
* Adicionada opção para gerar a ID do inventário.
* Exportação de ninhos e espécimes para CSV.

### Melhorias

* Melhorados processos de validação de formulários.
* O intervalo do timer dos inventários foi aumentado para conservar recursos.
* A frequência de carregamento dos dados do banco de dados foi reduzida para conservar recursos.
* Pré-carregamento da lista de nomes de espécies quando o aplicativo inicia.
* Tela de configurações reformulada.
* Navegação migrada para um painel lateral em telas menores.
* O inventário mostra uma notificação quando encerrar automaticamente.
* Para gerenciar inventários simultâneos, pode ser configurado um limite de inventários ativos.
* Quando uma espécie é apagada, pergunta se o usuário deseja apagar dos outros inventários ativos.

### Técnico/Dependências

* Revisado o método para manter a execução do app em segundo plano.

### Correções

* Corrigido um problema que o conteúdo de uma aba não era mostrado.
* Corrigido problema ao carregar a lista de revisões de ninho.
* Mostra as quantidades corretas de ovos e ninhegos na lista de revisões de ninho.
* Corrigidos problemas associados a listas de Mackinnon.
* Resolvido problema em que o tempo decorrido poderia não reiniciar ao adicionar uma nova espécie a um inventário.
* O método de parar o timer estava sendo acionado repetidamente quando o inventário encerrava automaticamente.
* Corrigido problema que evitava a criação da tabela de POIs no banco de dados.
* Corrigido método para recuperar a próxima ID ou número de campo para evitar duplicações.
* Resolvido problema que a ID do registro não era carregada após a inserção.
* Implementadas correções para o modo escura da interface de usuário.
* Corrigido problema onde campos eram salvos vazios no banco de dados.
* Corrigida opcão para apagar registro que não estava funcionando.

## 1.0.0

### Novas funcionalidades

* Novos tipos de inventário: anilhamento e observação casual.
* Entrada de dados do tempo nos inventários.
* Registro de ninhos e revisões de ninho.
* Registro de espécimes coletados.
* Criada tela de configurações com alguns valores de preferência do usuário.
* Adicionada tela com informações sobre o app e suas licenças.
* Opções para exportar todos inventários e todos ninhos para arquivo JSON.
* Opção para apagar os dados do app nas configurações.
* Menu com opções para items das listas aberto por pressionamento longo.
* Adaptado layout para telas maiores.
* Criação de inventários com ou sem temporizador.
* Sincronização de espécies adicionadas entre inventários ativos.
* Exportar inventários da lista de encerrados.
* Entrada de dados de vegetação nos inventários.
* Registro de pontos de interesse (POIs) para espécies nos inventários.
* Um som é tocado quando um inventário encerrar automaticamente.
* Mais feedback para o usuário, especialmente em tarefas que demandam tempo.

### Técnico/Dependências

* Código e estrutura de pastas refatorados.

### Correções

* Corrigido problema na atualização da lista de espécies dos inventários.
* Corrigido problema na pesquisa de espécies.
* Corrigido problema reativava um inventário encerrado ao adicionar uma espécie.
* Corrigidos alguns problemas relacionados ao temporizador dos inventários.
* Corrigido um problema onde o temporizador parava ao bloquear a tela.
* Melhorias na resposividade e corrigidos problemas de atualização da interface.
* Corrigido problema que adicionava espécies a inventários ativos quando adicionada em um inventário encerrado.
