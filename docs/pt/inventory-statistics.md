# Estatísticas dos Inventários Selecionados

O Xolmis Mobile permite comparar vários inventários finalizados usando uma tela dedicada de **Estatísticas**. Esse recurso ajuda a avaliar esforço amostral, riqueza de espécies, padrões temporais e o desempenho geral das amostragens em diferentes locais ou datas.

As estatísticas ficam disponíveis apenas quando **dois ou mais inventários finalizados** são selecionados. O relatório Espécies por Inventário fica disponível quando **um ou mais inventários finalizados** são selecionados.

## Acessando a Tela de Estatísticas

1. Abra o módulo **Inventários**.  
2. Vá para a aba **Finalizados**.  
3. Selecione dois ou mais inventários usando as caixas de seleção.  
4. Toque no botão :material-chart-box-outline: **Estatísticas** na barra inferior.  

Uma nova tela será aberta com informações resumidas e vários gráficos.

## Informações Resumidas

No topo da tela de estatísticas, você encontrará métricas importantes:

- **Inventários selecionados** – número total de inventários incluídos na comparação.  
- **Localidades amostradas** – número de localidades distintas representadas.  
- **Riqueza total** – número total de espécies únicas entre todos os inventários selecionados.  
- **Riqueza média** – média de espécies por inventário.
- **Espécies compartilhadas** – número de espécies que ocorrem em todos inventários selecionados, com botão de **Detalhes** que leva para listas detalhadas por pares de inventários, incluindo índices de similaridade de Jaccard e Sorensen.
- **Espécies exclusivas** – número de espécies que só ocorreram em um inventário selecionado, com botão de **Detalhes** que leva para listas detalhadas por pares de inventários, incluindo índices de similaridade de Jaccard e Sorensen.

Esses valores fornecem uma visão rápida da cobertura amostral e da diversidade.

## Curva de Acumulação de Espécies

Este gráfico mostra como as espécies se acumulam ao longo dos inventários selecionados.

- O **eixo X** representa os inventários na ordem em que foram selecionados.  
- O **eixo Y** mostra o número cumulativo de espécies.  
- Três linhas são exibidas:
  - **Linha rosa** – espécies dentro da amostra  
  - **Linha roxa** – todas as espécies, incluindo as fora da amostra
  - **Linha turquesa tracejada** - curva de rarefação (Mao Tau)

Essa visualização é especialmente útil para **listas de Mackinnon** ou levantamentos sequenciais, ajudando a avaliar a completude da amostragem.

### Acessando o relatório Espécies por Inventário

Abaixo do gráfico de acumulação de espécies há um botão para **Ver Tabela de Espécies**.

Uma nova tela será aberta com uma tabela de dados, onde:

- A primeira coluna lista todas as espécies registradas em ordem alfabética.
- A segunda coluna mostra o estado de conservação global da espécie.
- As colunas seguintes mostram um inventário por coluna, indicando presença (X - dentro da amostra, O - fora da amostra) ou abundância para cada espécie da primeira coluna, com o valor grifado quando for a primeira ocorrência da espécie nessa comparação.
- A penúltima coluna e a última linha mostram os totais das linhas e colunas.
- A última coluna mostra a frequência relativa das espécies.

Esse relatório pode ser exportado para CSV tocando no ícone **Exportar** no canto superior direito da tela.

## Registros por Hora

Um gráfico de barras mostrando o número de detecções de espécies (ou espécies adicionadas) por hora do dia.

- Ajuda a identificar **períodos de maior atividade**.  
- Útil para planejar levantamentos futuros ou entender o esforço do observador.  
- Pode revelar períodos pouco amostrados.

## Riqueza de Espécies por Inventário

Um gráfico de barras comparando o número total de espécies registradas em cada inventário selecionado.

- **Eixo X** – inventários  
- **Eixo Y** – riqueza de espécies  

Útil para comparar:

- Diferentes habitats  
- Diferentes datas  
- Diferentes observadores  
- Diferentes métodos de amostragem  

Esse gráfico ajuda a destacar inventários com riqueza excepcionalmente alta ou baixa.

## Estado de Conservação

Gráfico de barras que mostra a distribuição das espécies nas diferentes categorias de estado de conservação global.

Caso alguma espécie esteja em alguma categoria de ameaça, abaixo do gráfico é disponibilizado um botão **Ver Tabela de Espécies**, que abre a lista das espécies registradas ameaçadas.

## Índices de Biodiversidade

### Indicadores de diversidade

- **Riqueza observada (Hill N0)** - riqueza observada (`S`) e Número de Hill N0 (q=0), que são equivalentes.
- **Total de indivíduos** - abundância total (`N`).
- **Índice de Shannon-Wiener (H')**: mede a diversidade considerando tanto a riqueza quanto a equitabilidade, sendo sensível a espécies raras.
- **Índice de Simpson (1-D)**: mede a probabilidade de dois indivíduos selecionados ao acaso pertencerem a espécies diferentes, sendo mais sensível às espécies dominantes.
- **Equitabilidade de Pielou (J')**: mede quão uniformemente os indivíduos estão distribuídos entre as espécies presentes (varia de 0 a 1).
- **Números de Hill**: família unificada de índices que expressam a diversidade em termos de número efetivo de espécies.
  - **Hill N1 (q=1)**: exponencial do índice de Shannon; pondera as espécies de acordo com sua abundância proporcional.
  - **Hill N2 (q=2)**: inverso do índice de Simpson; dá maior peso às espécies dominantes.
- **Estimador de riqueza Chao1**: estimativa não paramétrica da riqueza total de espécies baseada na proporção de espécies raras (*singletons* e *doubletons*).

### Índices por Inventário

Tabela com os mesmos indicadores de diversidade calculados para cada inventário selecionado.

## Quando Usar as Estatísticas de Inventários

A tela de estatísticas é especialmente útil para:

- Comparar múltiplos locais de amostragem  
- Avaliar esforço de levantamento entre dias ou observadores  
- Analisar padrões temporais de detecção de espécies  
- Avaliar a eficácia de diferentes métodos  
- Revisar dados antes de exportar ou importar para o Xolmis Desktop  

Essas ferramentas fornecem um resumo visual rápido do seu trabalho de campo e ajudam a orientar análises posteriores.

---

O recurso Estatísticas dos Inventários Selecionados oferece uma visão poderosa dos seus dados de levantamento, ajudando você a entender padrões, detectar tendências e tomar decisões informadas sobre amostragens futuras.
