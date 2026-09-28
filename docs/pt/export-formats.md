# Formatos de Arquivos Exportados

O Xolmis Mobile permite exportar dados de todos os seus módulos—**Inventários**, **Ninhos**, **Espécimes** e **Diário de Campo**—bem como gerar **Backups Completos do Banco de Dados**. Este guia fornece uma especificação detalhada de cada formato de exportação suportado, explicando como os arquivos são gerados e descrevendo as colunas de cada conjunto de dados tabulares.

## Visão Geral e Regras de Geração de Arquivos

Dependendo do formato escolhido, uma operação de exportação pode gerar **um único arquivo** ou **múltiplos arquivos**:

| Módulo / Ação | Formato | Quantidade de Arquivos Gerados | Detalhes                                                                                                                                                            |
| :--- | :--- |:-------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Inventários** | **CSV** | Até **4 arquivos**             | Gera arquivos separados: `..._species.csv`, `..._pois.csv` (se houver), `..._vegetation.csv` (se houver medições) e `..._weather.csv` (se houver dados climáticos). |
| | **Excel** | **1 arquivo**                  | Gera uma planilha `.xlsx` única contendo até 5 abas: `Occurrences`, `Vegetation`, `Weather`, `POIs` e `Events`.                                                     |
| | **JSON** | **1 arquivo**                  | Arquivo `.json` único envolvido em um envelope padronizado.                                                                                                         |
| | **KML** | **1 arquivo**                  | Arquivo espacial `.kml` único com pontos de início/fim e POIs de espécies.                                                                                          |
| **Ninhos** | **CSV** | Até **2 arquivos**             | Gera arquivos separados: `..._revisions.csv` e `..._eggs.csv` (se houver medições de ovos).                                                                         |
| | **Excel** | **1 arquivo**                  | Gera uma planilha `.xlsx` única contendo até 3 abas: `Revisions`, `Nests` (resumo) e `Eggs`.                                                                        |
| | **JSON** | **1 arquivo**                  | Arquivo `.json` único envolvido em um envelope padronizado.                                                                                                         |
| | **KML** | **1 arquivo**                  | Arquivo espacial `.kml` único contendo a localização dos ninhos.                                                                                                    |
| **Espécimes** | **CSV** | **1 arquivo**                  | Gera o arquivo `..._specimens.csv`.                                                                                                                                 |
| | **Excel** | **1 arquivo**                  | Gera uma planilha `.xlsx` única com a aba `Specimens`.                                                                                                              |
| | **JSON** | **1 arquivo**                  | Arquivo `.json` único envolvido em um envelope padronizado.                                                                                                         |
| | **KML** | **1 arquivo**                  | Arquivo espacial `.kml` único contendo as localizações de coleta.                                                                                                   |
| **Diário de Campo** | **Texto Simples** | **1 arquivo**                  | Arquivo `.txt` único formatado com as anotações.                                                                                                                    |
| | **Markdown** | **1 arquivo**                  | Arquivo `.md` único formatado com cabeçalhos e metadados.                                                                                                           |
| | **Word** | **1 arquivo**                  | Documento Word `.docx` único com estilos em títulos e parágrafos.                                                                                                   |
| | **JSON** | **1 arquivo**                  | Arquivo `.json` único contendo estruturas Delta JSON envelopadas.                                                                                                   |
| **Backup** | **ZIP** | **1 arquivo**                  | Arquivo compactado contendo o banco de dados `xolmis_database.db` e todas as fotos anexadas.                                                                        |

!!! note

    **Paridade de Colunas entre CSV e Excel**: Arquivos CSV e planilhas Excel compartilham exatamente a mesma estrutura de colunas. Nas exportações em CSV, cada categoria de dados é gerada como um arquivo CSV independente (delimitado por ponto e vírgula `;` ou vírgula, conforme as configurações). Nas exportações em Excel, essas mesmas categorias são combinadas como abas organizadas em um único arquivo `.xlsx`.

## Conjuntos de Dados Tabulares (Colunas em CSV e Excel)

Todas as exportações tabulares do Xolmis Mobile são alinhadas aos padrões do **Darwin Core (DwC)** quando aplicável, facilitando a integração com plataformas de dados de biodiversidade (como GBIF e Xolmis Desktop).

### 1. Módulo de Inventários

#### Tabela de Ocorrências (`..._species.csv` / Aba no Excel: `Occurrences`)

Contém os registros de espécies e os parâmetros de observação coletados durante os inventários.

| Nome da Coluna | Tipo de Dado | Descrição |
| :--- | :--- | :--- |
| `eventID` | Texto | Identificador único da sessão de inventário (ex.: `CRS-20260330-001`). |
| `samplingProtocol` | Texto | Metodologia do inventário (ex.: *Point Count*, *Transect*, *Mackinnon List*, *Casual*). |
| `samplingEffort` | Inteiro | Duração ou esforço planejado em minutos. |
| `eventDate` | Texto | Data de início (`YYYY-MM-DD`). |
| `eventTime` | Texto | Hora de início (`HH:MM:SS`). |
| `eventEndDate` | Texto | Data de encerramento (`YYYY-MM-DD`). |
| `eventEndTime` | Texto | Hora de encerramento (`HH:MM:SS`). |
| `locality` | Texto | Nome da localidade ou ponto de amostragem. |
| `decimalLongitude` | Decimal | Longitude inicial do inventário (graus decimais). |
| `decimalLatitude` | Decimal | Latitude inicial do inventário (graus decimais). |
| `endLongitude` | Decimal | Longitude final do inventário (graus decimais). |
| `endLatitude` | Decimal | Latitude final do inventário (graus decimais). |
| `recordedBy` | Texto | Iniciais ou nome do observador. |
| `totalObservers` | Inteiro | Número total de observadores na equipe. |
| `samplingIntervals` | Inteiro | Intervalo ativo ou total de intervalos configurados. |
| `pausedTimeSeconds` | Inteiro | Tempo total de pausa acumulado durante o inventário (em segundos). |
| `eventRemarks` | Texto | Observações gerais sobre o inventário. |
| `isDiscarded` | Texto | Indica se a sessão foi marcada como descartada (`Yes`/`No`). |
| `scientificName` | Texto | Nome científico da espécie observada. |
| `individualCount` | Inteiro | Quantidade de indivíduos observados. |
| `occurrenceTime` | Texto | Horário do registro da espécie (`HH:MM:SS` ou `YYYY-MM-DD HH:MM:SS`). |
| `isOutOfSample` | Texto | Indica se a observação ocorreu fora do tempo padronizado (`Yes`/`No`). |
| `distance` | Texto | Categoria de distância ou distância estimada do indivíduo. |
| `flightHeight` | Texto | Categoria ou estimativa de altura de voo. |
| `flightDirection` | Texto | Direção de voo ou deslocamento. |
| `occurrenceRemarks` | Texto | Observações específicas deste registro de espécie. |

#### Tabela de Vegetação (`..._vegetation.csv` / Aba no Excel: `Vegetation`)

Contém medições de estrutura da vegetação e habitat associadas aos inventários.

| Nome da Coluna | Tipo de Dado | Descrição |
| :--- | :--- | :--- |
| `eventID` | Texto | Identificador da sessão de inventário. |
| `samplingProtocol` | Texto | Metodologia do inventário. |
| `samplingEffort` | Inteiro | Duração planejada em minutos. |
| `eventDate` | Texto | Data de início do inventário (`YYYY-MM-DD`). |
| `eventTime` | Texto | Hora de início do inventário (`HH:MM:SS`). |
| `locality` | Texto | Nome da localidade. |
| `decimalLongitude` | Decimal | Longitude inicial. |
| `decimalLatitude` | Decimal | Latitude inicial. |
| `recordedBy` | Texto | Iniciais do observador. |
| `eventRemarks` | Texto | Observações do inventário. |
| `measurementDate` | Texto | Data e hora da medição da vegetação (`YYYY-MM-DD HH:MM:SS`). |
| `measurementLatitude` | Decimal | Latitude onde a vegetação foi amostrada. |
| `measurementLongitude` | Decimal | Longitude onde a vegetação foi amostrada. |
| `herbsProportion` | Decimal/Int | Porcentagem de cobertura do estrato herbáceo (0–100%). |
| `herbsDistribution` | Texto | Padrão de distribuição espacial de herbáceas (*Continuous*, *Clumped*, *Sparse*). |
| `herbsHeight` | Decimal | Altura média/máxima do estrato herbáceo. |
| `shrubsProportion` | Decimal/Int | Porcentagem de cobertura do estrato arbustivo (0–100%). |
| `shrubsDistribution` | Texto | Padrão de distribuição espacial de arbustos. |
| `shrubsHeight` | Decimal | Altura média/máxima do estrato arbustivo. |
| `treesProportion` | Decimal/Int | Porcentagem de cobertura do estrato arbóreo/dossel (0–100%). |
| `treesDistribution` | Texto | Padrão de distribuição espacial de árvores. |
| `treesHeight` | Decimal | Altura média/máxima do estrato arbóreo. |
| `measurementRemarks` | Texto | Observações sobre a amostragem de vegetação. |

#### Tabela de Clima (`..._weather.csv` / Aba no Excel: `Weather`)

Contém amostras das condições atmosféricas registradas durante o inventário.

| Nome da Coluna | Tipo de Dado | Descrição |
| :--- | :--- | :--- |
| `eventID` | Texto | Identificador da sessão de inventário. |
| `samplingProtocol` | Texto | Metodologia do inventário. |
| `samplingEffort` | Inteiro | Duração planejada em minutos. |
| `eventDate` | Texto | Data de início do inventário (`YYYY-MM-DD`). |
| `eventTime` | Texto | Hora de início do inventário (`HH:MM:SS`). |
| `locality` | Texto | Nome da localidade. |
| `decimalLongitude` | Decimal | Longitude inicial. |
| `decimalLatitude` | Decimal | Latitude inicial. |
| `recordedBy` | Texto | Iniciais do observador. |
| `eventRemarks` | Texto | Observações do inventário. |
| `measurementDate` | Texto | Data e hora da medição climática (`YYYY-MM-DD HH:MM:SS`). |
| `cloudCover` | Texto/Int | Porcentagem ou categoria de cobertura de nuvens. |
| `precipitation` | Texto | Status ou intensidade de precipitação (*None*, *Light Rain*, *Heavy Rain*, etc.). |
| `temperature` | Decimal | Temperatura ambiente (°C). |
| `windSpeed` | Texto/Decimal | Velocidade do vento ou categoria na escala Beaufort. |
| `windDirection` | Texto | Direção do vento (ex.: *N*, *NE*, *350°*). |
| `atmosphericPressure` | Decimal | Pressão atmosférica (hPa). |
| `relativeHumidity` | Decimal | Umidade relativa do ar (%). |

#### Tabela de Pontos de Interesse (`..._pois.csv` / Aba no Excel: `POIs`)

Incluída nas planilhas Excel para registrar waypoints de GPS individuais marcados durante a observação de espécies.

| Nome da Coluna | Tipo de Dado | Descrição |
| :--- | :--- | :--- |
| `eventID` | Texto | Identificador da sessão de inventário. |
| `samplingProtocol` | Texto | Metodologia do inventário. |
| `eventDate` | Texto | Data de início do inventário (`YYYY-MM-DD`). |
| `locality` | Texto | Nome da localidade. |
| `recordedBy` | Texto | Iniciais do observador. |
| `scientificName` | Texto | Nome científico da espécie associada ao POI. |
| `poiDate` | Texto | Data/hora em que as coordenadas do POI foram capturadas (`YYYY-MM-DD HH:MM:SS`). |
| `decimalLatitude` | Decimal | Latitude do ponto de interesse. |
| `decimalLongitude` | Decimal | Longitude do ponto de interesse. |
| `poiRemarks` | Texto | Observações gravadas no POI. |

#### Tabela de Resumo de Eventos (Aba no Excel: `Events`)

Incluída nas planilhas Excel para resumir os metadados da sessão de cada inventário.

| Nome da Coluna | Tipo de Dado | Descrição |
| :--- | :--- | :--- |
| `eventID` | Texto | Identificador único da sessão de inventário. |
| `samplingProtocol` | Texto | Metodologia do inventário. |
| `samplingEffort` | Inteiro | Duração planejada em minutos. |
| `maxSpecies` | Inteiro | Capacidade de lista de espécies (para Listas de Mackinnon). |
| `eventDate` | Texto | Data de início (`YYYY-MM-DD`). |
| `eventTime` | Texto | Hora de início (`HH:MM:SS`). |
| `eventEndDate` | Texto | Data de encerramento (`YYYY-MM-DD`). |
| `eventEndTime` | Texto | Hora de encerramento (`HH:MM:SS`). |
| `locality` | Texto | Nome da localidade. |
| `decimalLongitude` | Decimal | Longitude inicial. |
| `decimalLatitude` | Decimal | Latitude inicial. |
| `endLongitude` | Decimal | Longitude final. |
| `endLatitude` | Decimal | Latitude final. |
| `totalObservers` | Inteiro | Número total de observadores. |
| `recordedBy` | Texto | Iniciais do observador principal. |
| `samplingIntervals` | Inteiro | Total de intervalos configurados ou executados. |
| `pausedTimeSeconds` | Inteiro | Tempo total pausado em segundos. |
| `eventRemarks` | Texto | Observações gerais do inventário. |
| `isDiscarded` | Texto | Indicador de descarte (`Yes`/`No`). |

### 2. Módulo de Ninhos

#### Tabela Resumo de Ninhos (Aba no Excel: `Nests`)

Registros gerais dos ninhos encontrados.

| Nome da Coluna | Tipo de Dado | Descrição |
| :--- | :--- | :--- |
| `occurrenceID` | Texto | Código / número de campo do ninho (ex.: `N-001`). |
| `scientificName` | Texto | Nome científico da espécie hospedeira. |
| `locality` | Texto | Nome da localidade ou área de estudo. |
| `decimalLongitude` | Decimal | Longitude da localização do ninho. |
| `decimalLatitude` | Decimal | Latitude da localização do ninho. |
| `verbatimEventDate` | Texto | Data/hora de descoberta do ninho (`YYYY-MM-DD HH:MM:SS`). |
| `support` | Texto | Substrato, espécie vegetal ou suporte do ninho. |
| `heightAboveGround` | Decimal | Altura em relação ao solo (em metros). |
| `male` | Texto | Status, anilha ou observações sobre o macho. |
| `female` | Texto | Status, anilha ou observações sobre a fêmea. |
| `helpers` | Texto | Observações sobre indivíduos ajudantes de ninho. |
| `lastEventDate` | Texto | Data/hora da última revisão (`YYYY-MM-DD HH:MM:SS`). |
| `recordedBy` | Texto | Iniciais do observador principal. |
| `nestFate` | Texto | Destino / desfecho final do ninho (*Active*, *Successful*, *Predated*, *Abandoned*, *Discarded*). |

#### Tabela de Revisões (`..._revisions.csv` / Aba no Excel: `Revisions`)

Visitas periódicas de monitoramento registradas nos ninhos.

| Nome da Coluna | Tipo de Dado | Descrição |
| :--- | :--- | :--- |
| `occurrenceID` | Texto | Número de campo do ninho. |
| `scientificName` | Texto | Nome científico da espécie hospedeira. |
| `locality` | Texto | Nome da localidade. |
| `decimalLongitude` | Decimal | Longitude. |
| `decimalLatitude` | Decimal | Latitude. |
| `recordedBy` | Texto | Iniciais do observador. |
| `eventTime` | Texto | Data/hora da visita de revisão (`YYYY-MM-DD HH:MM:SS`). |
| `nestStatus` | Texto | Condição física do ninho (*Construction*, *Intact*, *Damaged*, *Destroyed*). |
| `nestStage` | Texto | Estágio reprodutivo (*Building*, *Egg-laying*, *Incubation*, *Nestling*, *Empty*). |
| `eggsHost` | Inteiro | Contagem de ovos da espécie hospedeira. |
| `nestlingsHost` | Inteiro | Contagem de nestagões/filhotes da espécie hospedeira. |
| `eggsParasite` | Inteiro | Contagem de ovos de parasitas de ninho (ex.: Vira-bochecha / *Molothrus bonariensis*). |
| `nestlingsParasite` | Inteiro | Contagem de filhotes de parasitas de ninho. |
| `hasPhilornisLarvae` | Texto | Presença de larvas de berne (*Philornis* spp.) (`Yes`/`No`). |
| `revisionRemarks` | Texto | Observações registradas durante a visita de revisão. |

#### Tabela de Ovos (`..._eggs.csv` / Aba no Excel: `Eggs`)

Medições biométricas dos ovos presentes na postura.

| Nome da Coluna | Tipo de Dado | Descrição |
| :--- | :--- | :--- |
| `occurrenceID` | Texto | Número de campo do ninho. |
| `scientificName` | Texto | Nome científico da espécie hospedeira. |
| `locality` | Texto | Nome da localidade. |
| `eventTime` | Texto | Data/hora da medição do ovo (`YYYY-MM-DD HH:MM:SS`). |
| `eggFieldNumber` | Texto | Código / identificador do ovo dentro da postura. |
| `eggSpeciesName` | Texto | Espécie associada ao ovo (hospedeira ou parasita). |
| `eggShape` | Texto | Formato do ovo (*Oval*, *Elliptical*, *Subelliptical*, *Pyriform*). |
| `width` | Decimal | Largura do ovo em milímetros. |
| `length` | Decimal | Comprimento do ovo em milímetros. |
| `mass` | Decimal | Massa do ovo em gramas. |

### 3. Módulo de Espécimes

#### Tabela de Espécimes (`..._specimens.csv` / Aba no Excel: `Specimens`)

Registros de amostras biológicas, espécimes de testemunho, amostras de sangue ou evidências físicas.

| Nome da Coluna | Tipo de Dado | Descrição |
| :--- | :--- | :--- |
| `verbatimEventDate` | Texto | Data/hora de obtenção do espécime (`YYYY-MM-DD HH:MM:SS`). |
| `occurrenceID` | Texto | Número de campo / código do espécime (ex.: `SPEC-001`). |
| `recordedBy` | Texto | Iniciais do coletor ou observador. |
| `scientificName` | Texto | Nome científico da espécie. |
| `basisOfRecord` | Texto | Tipo de registro (*Physical Specimen*, *Blood Sample*, *Feather*, *Photo*, *Audio Recording*). |
| `locality` | Texto | Nome da localidade ou ponto de coleta. |
| `decimalLongitude` | Decimal | Longitude da coleta. |
| `decimalLatitude` | Decimal | Latitude da coleta. |
| `occurrenceRemarks` | Texto | Observações sobre o espécime, tecido preservado ou local de armazenamento. |

## Formato JSON e Envelope de Dados

As exportações em JSON são o formato padrão para transferência de dados entre dispositivos com Xolmis Mobile ou integração com o **Xolmis Desktop**.

Cada arquivo JSON exportado contém um envelope padronizado de metadados:

```json
{
  "source": "Xolmis Mobile",
  "schema": "inventories",
  "schemaVersion": "1",
  "records": [
    { ... }
  ]
}
```

### Campos do Envelope JSON

- `source`: Sempre definido como `"Xolmis Mobile"`.
- `schema`: Identifica o módulo exportado (`"inventories"`, `"nests"`, `"specimens"`, `"journals"`).
- `schemaVersion`: Versão do esquema de dados (atualmente `"1"`).
- `records`: Array JSON contendo a estrutura completa dos objetos (incluindo sub-listas de espécies, POIs, medições de vegetação, dados climáticos, revisões de ninho e ovos).

## Formato Espacial KML

As exportações em **KML (Keyhole Markup Language)** permitem visualizar registros geográficos no Google Earth, softwares de SIG ou ferramentas de mapas online.

### Conteúdo dos Arquivos KML

- **Inventarios**:
  - Ponto inicial de amostragem (`<Placemark>`)
  - Ponto final de amostragem (`<Placemark>`)
  - Waypoints de Pontos de Interesse (POIs) marcados em observações de espécies, incluindo data/hora e coordenadas.
- **Ninhos**:
  - Waypoints com a localização dos ninhos contendo número de campo, espécie, suporte, altura e desfecho.
- **Espécimes**:
  - Waypoints dos pontos de coleta com número de campo, tipo de amostra e observações.

!!! note

    As coordenadas em arquivos KML utilizam estritamente a ordem `longitude,latitude,altitude`, seguindo a especificação oficial OGC.

## Formatos do Diário de Campo

O módulo **Diário de Campo** oferece formatos flexíveis de exportação para relatórios, publicações ou arquivamento:

- **Texto Simples (`.txt`)**: Texto limpo contendo título da nota, observador, datas de criação/modificação, tags e o corpo da nota.
- **Markdown (`.md`)**: Documento formatado em Markdown com títulos (`# Título`), metadados em negrito e parágrafos estruturados.
- **Word (`.docx`)**: Documento do Microsoft Word formatado com estilos nativos de títulos, metadados e parágrafos.
- **JSON (`.json`)**: Estrutura nativa Delta JSON formatada com estilo rich-text dentro do envelope `journals`.

## Backup Completo do Banco de Dados (ZIP)

Os arquivos de backup do banco de dados são gerados em **Configurações → Backup**.

### Estrutura do Arquivo de Backup (`.zip`)

- `xolmis_database.db`: Arquivo SQLite completo contendo todos os registros, tabelas e configurações do aplicativo.
- `[nome_imagem].jpg / .png`: Todas as imagens fotográficas cadastradas na tabela `images` (anexadas a inventários, vegetação, ninhos, espécimes ou diário de campo).

A restauração de um backup substitui com segurança o banco de dados local e restaura os arquivos de mídia para a pasta de documentos do aplicativo.
