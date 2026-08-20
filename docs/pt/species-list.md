# Lista de Espécies e Registros

A **lista de espécies** (ou **lista de registros**, dependendo do tipo de inventário) é o componente central de todo inventário no Xolmis Mobile. Ela exibe todas as espécies detectadas durante o levantamento e oferece ferramentas para gerenciar contagens, adicionar coordenadas, editar notas e organizar suas observações de forma eficiente.

Esta seção explica como usar a lista de espécies durante o trabalho de campo.

## Adicionando uma Espécie

1. Abra um inventário.  
2. Toque no campo **Adicionar espécie** no topo da lista.  
3. Digite parte do nome científico. Você pode usar:
   - Iniciais do gênero + espécie (ex.: `peob` ou `penobs` → *Penelope obscura*)  
   - Correspondências parciais (ex.: `muscu` → *Troglodytes musculus*)  
   - Múltiplos fragmentos separados por espaços (ex.: `pen obs` → *Penelope obscura*)
   - Quantidade de indivíduos + vírgula + busca de espécie (ex.: `32,chrruf` → *Chrysomus ruficapillus* x 32)
4. Selecione a espécie nas sugestões.

Se a espécie for adicionada após o inventário ser finalizado, ela será marcada como **fora da amostra**.

Se a espécie já estiver na lista:

- Se o inventário for do tipo **Transecto de Detecções** ou **Ponto de Detecções**, adiciona um novo registro da espécie.
- Se o inventário for do tipo **Contagem em Transecto** ou **Ponto de Contagem**, pergunta se quer adicionar à contagem da espécie. Se foi digitada a quantidade de indivíduos na busca, adiciona à contagem da espécie sem perguntar.
- Outros tipos de inventários mostram uma mensagem e não adicionam nada.

### Adicionando uma espécie personalizada

Se a espécie não for encontrada:

- Toque no menu **⋮** na barra de busca  
- Selecione **Adicionar espécie**  
- Digite um nome temporário  

O nome personalizado aparecerá exatamente como foi digitado, destacado em vermelho.

## Ajustando o Número de Indivíduos

Para métodos quantitativos (transectos, pontos de escuta, anilhamento etc.):

- Use os botões **+** e **–** ao lado do nome da espécie.  
- Toque no número para inserir valores grandes manualmente.  
- A contagem padrão é **1** ao adicionar uma espécie.

Listas qualitativas não registram contagens de indivíduos.

## Adicionando POIs (Pontos de Interesse)

Um POI armazena as **coordenadas GPS** de uma espécie ou detecção de espécie.

Para adicionar um POI:

1. Toque no **ícone de GPS** à direita da espécie.  
2. O app registra a localização atual do dispositivo.  

Para visualizar ou gerenciar POIs:

- Toque no **nome da espécie** para abrir a tela de detalhes.  
- Toque e segure um POI para:
  - Ver detalhes  
  - Adicionar notas  
  - Excluir o POI  

POIs são incluídos ao exportar para **KML**.

## Editando Detalhes da Espécie

Toque e segure uma espécie na lista para abrir o menu de ações:

- **Detalhes** – Adicionar notas ou alterar a espécie.  
- **Remover da amostra** – Marca a espécie como registrada fora do período de amostragem.  
- **Incluir na amostra** – Reverte a ação acima.  
- **Adicionar POI** – Registra uma nova coordenada.  
- **Excluir** – Remove a espécie e todos os POIs associados.

## Espécies Dentro vs. Fora da Amostra

Espécies adicionadas **após finalizar** um inventário são marcadas:

- **Cinza**  
- Com o rótulo **fora da amostra**

Essa distinção é importante para:

- Listas de Mackinnon  
- Curvas de acumulação  
- Estatísticas  
- Relatórios exportados  

## Métodos Baseados em Detecção

Para inventários de **Transecto de Detecção** e **Ponto de Detecção**:

- Cada detecção é um **registro separado**, não uma única entrada de espécie.  
- Após selecionar a espécie, um formulário é aberto para preencher:
  - Distância  
  - Altura de voo  
  - Direção de voo  
  - Tamanho do grupo  

Esses inventários permitem **múltiplas entradas da mesma espécie**.

## Ordenando a Lista de Espécies

Toque no **ícone de ordenação** para escolher como a lista será organizada.  
As opções podem incluir:

- Espécie (alfabética)  
- Hora de adição  

A ordenação ajuda em levantamentos longos ou na revisão dos dados.

## Mais Opções (Menu ⋮)

O menu **⋮** na barra de busca oferece ferramentas adicionais:

- **Adicionar espécie** (nome personalizado)  
- **Gráfico de acumulação de espécies**  

Essas ferramentas ajudam a avaliar a completude da amostragem e o desempenho do inventário.

## Sincronização Entre Inventários Ativos

Quando vários inventários estão ativos:

- Adicionar uma espécie a um inventário **automaticamente a adiciona aos demais**,  
  exceto inventários de **Anilhamento**.

Isso permite:

- Executar uma lista qualitativa em paralelo com pontos de escuta ou transectos  
- Consolidação automática das espécies detectadas durante a sessão  

## Sugestões Automáticas

Quando a lista de espécies está vazia, o app pode exibir **sugestões de ação**, como:

- Adicionar espécie  

Essas sugestões ajudam a guiar novos usuários.

A lista de espécies/registros foi projetada para ser rápida, flexível e adequada ao campo, garantindo que suas observações sejam registradas com precisão e eficiência em qualquer tipo de levantamento.

*[POI]: Point of Interest
