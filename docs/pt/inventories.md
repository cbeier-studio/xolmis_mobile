# Gerenciar Inventários

O módulo **Inventários** é o núcleo do Xolmis Mobile, permitindo registrar listas de espécies usando diferentes métodos de amostragem. Esta seção explica como criar, editar, finalizar, reativar, excluir, importar, exportar, buscar, ordenar e selecionar inventários.

## Criar um Inventário

1. Abra **Inventários** no menu principal.  
2. Toque no botão **+** no canto inferior direito.  
3. Escolha o **tipo de inventário** (qualitativo, temporizado, intervalos, Mackinnon, transecto, ponto de escuta etc.).  
4. Preencha os campos necessários:
   - **ID** (ou gere automaticamente)
   - **Localidade**
   - **Duração** (se aplicável)
   - **Máximo de espécies** (se aplicável)
   - **Total de observadores**
5. Toque em **Iniciar inventário**.

O inventário começa imediatamente e aparece na aba **Ativos**.

## Editar um Inventário

Para editar um inventário existente:

1. Toque e segure o inventário na lista.  
2. Selecione **Editar**.  
3. Modifique campos como:
   - ID  
   - Localidade  
   - Total de observadores  
   - Status de descartado  

As edições são salvas automaticamente ao confirmar.

## Finalizar um Inventário

Você pode finalizar um inventário manualmente ou deixá-lo finalizar automaticamente (dependendo do método).

### Finalização manual

1. Abra o inventário.  
2. Toque no ícone **Finalizar** (bandeira).  
3. Confirme a ação.

Se lembretes de vegetação ou clima estiverem ativados, o app solicitará que você preencha os dados faltantes.

### Finalização automática

Alguns métodos terminam automaticamente:
- Listas temporizadas (quando o cronômetro chega a zero)  
- Listas por intervalos (após três intervalos vazios)  
- Pontos de escuta (após a duração definida)

## Reativar um Inventário

Inventários finalizados podem ser reabertos se necessário.

1. Toque e segure um inventário **finalizado**.  
2. Selecione **Reativar**.

O inventário retorna à aba **Ativos** e pode ser editado novamente.

## Excluir um Inventário

Você pode excluir um único inventário ou vários de uma vez.

### Excluir um

1. Toque e segure o inventário.  
2. Toque em **Excluir**.  
3. Confirme.

### Excluir vários

1. Toque na caixa de seleção ao lado de cada inventário.  
2. Toque no ícone **Excluir** (lixeira) na barra inferior.  
3. Confirme.

Excluir um inventário remove todas as espécies, POIs, dados de vegetação e clima associados.

## Selecionar Inventários

Selecionar inventários permite ações em lote, como exportar, excluir ou gerar relatórios.

1. Toque na **caixa de seleção** à esquerda de cada item.  
2. Uma barra de ações aparece na parte inferior com:
   - **Excluir**
   - **Exportar**
   - **Mais opções** (comparação de espécies, estatísticas)
   - **Limpar seleção**

## Importar Inventários

O Xolmis Mobile permite importar inventários de arquivos JSON exportados por outros usuários ou dispositivos.

1. Abra **Inventários**.  
2. Toque no menu **⋮** no canto superior direito.  
3. Selecione **Importar**.  
4. Escolha um arquivo JSON.  
5. O app processará o arquivo e informará o resultado.

O comportamento de importação para registros existentes pode ser configurado em **Configurações → Importação e Exportação**.

## Exportar Inventários

Inventários podem ser exportados individualmente ou em grupos.

### Exportar um

1. Toque e segure o inventário.  
2. Escolha o formato de exportação:
   - **CSV**
   - **Excel** (experimental)
   - **JSON**
   - **KML** (incluindo POIs)

### Exportar vários

1. Selecione dois ou mais inventários.  
2. Toque no ícone **Exportar**.  
3. Escolha o formato desejado.

### Exportar todos os inventários finalizados

1. Toque no menu **⋮** no canto superior direito.  
2. Selecione **Exportar todos (JSON)**.

Um painel de compartilhamento aparecerá para enviar o arquivo para a nuvem ou outro dispositivo.

## Buscar Inventários

Use a barra de busca no topo da tela para encontrar inventários por:

- ID  
- Localidade  

A busca atualiza os resultados instantaneamente conforme você digita.

## Ordenar Inventários

Toque no **ícone de ordenação** na barra de busca para abrir as opções.

Você pode ordenar por:

- ID  
- Localidade  
- Hora inicial  
- Hora final  
- Tipo de inventário  

Cada campo pode ser ordenado em ordem crescente ou decrescente.

---

Gerenciar inventários de forma eficiente ajuda a manter seu trabalho de campo organizado e garante uma integração suave com o Xolmis Desktop para armazenamento e análise de longo prazo.

*[CSV]: Comma Separated Values  
*[JSON]: JavaScript Object Notation  
*[KML]: Keyhole Markup Language
