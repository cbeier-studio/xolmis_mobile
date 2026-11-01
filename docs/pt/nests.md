# Gerenciar Ninhos

O módulo **Ninhos** permite registrar e gerenciar ninhos encontrados durante o trabalho de campo. Cada ninho inclui informações básicas como espécie, localidade, número de campo e suporte do ninho. A partir deste módulo, você pode criar, editar, inativar, reativar, excluir, importar, exportar, buscar, filtrar e ordenar ninhos.

Esta seção foca no gerenciamento dos próprios ninhos, sem incluir revisões ou ovos.

## Criar um Novo Ninho

1. Abra o módulo **Ninhos** no menu principal.  
2. Toque no botão **+** no canto inferior direito.  
3. Preencha os campos obrigatórios:
   - **Número de campo** (gerado automaticamente usando a abreviação do observador)  
   - **Espécie**  
   - **Localidade**  
   - **Suporte do ninho**  
4. Opcionalmente, adicione detalhes adicionais.  
5. Toque em **Salvar**.

Novos ninhos aparecem na aba **Ativos**.

## Visualizar e Editar Detalhes do Ninho

Toque e segure qualquer ninho na lista para abrir o menu.  
Você pode editar as informações do ninho a qualquer momento:

1. Toque no ícone **Editar**.  
2. Modifique os campos desejados.  
3. Salve suas alterações.

As edições são aplicadas imediatamente.

## Inativar (Finalizar) um Ninho

Quando o monitoramento de um ninho estiver concluído, você pode marcá-lo como **inativo**.

1. Abra o ninho.  
2. Toque no ícone **Finalizar** (bandeira).  
3. Selecione o destino final do ninho (ex.: sucesso, perdido, desconhecido).  
4. Confirme.

Ninhos inativos são movidos para a aba **Inativos**.

## Reativar um Ninho

Se precisar continuar o monitoramento ou corrigir um erro, você pode reativar um ninho inativo.

1. Toque e segure o ninho na lista.  
2. Selecione **Reativar**.

O ninho retorna à aba **Ativos**.

## Excluir Ninhos

Você pode excluir um ou vários ninhos.

### Excluir um único ninho

1. Toque e segure o ninho.  
2. Toque em **Excluir**.  
3. Confirme.

### Excluir vários ninhos

1. Selecione os ninhos usando as caixas de seleção.  
2. Toque no ícone **Excluir** (lixeira).  
3. Confirme.

Excluir um ninho remove todos os dados associados.

## Importar Ninhos

Você pode importar ninhos a partir de arquivos JSON exportados por outro dispositivo ou usuário.

1. Abra **Ninhos**.  
2. Toque no menu **⋮** no canto superior direito.  
3. Selecione **Importar**.  
4. Escolha um arquivo JSON.  
5. Aguarde a confirmação da importação.

O comportamento de importação para ninhos existentes pode ser configurado em **Configurações → Importação e Exportação**.

## Exportar Ninhos

Ninhos podem ser exportados individualmente ou em grupos.

### Exportar um ninho

1. Toque e segure o ninho.
2. Toque na opção **Exportar**.
3. Defina o prefixo do nome do arquivo, se desejar. Um sufixo com data e hora da exportação são automaticamente adicionados ao nome do arquivo.
4. Selecione um ou mais formatos de exportação:
   - **CSV**
   - **Excel**
   - **JSON**
   - **KML**
5. Toque no botão **Exportar**.

### Exportar vários ninhos

1. Selecione os ninhos usando as caixas de seleção.  
2. Toque no ícone **Exportar**.  
3. Defina o prefixo do nome do arquivo, se desejar.
4. Selecione um ou mais formatos de exportação.
5. Toque no botão **Exportar**.

### Exportar todos os ninhos inativos

1. Toque no menu **⋮**.  
2. Selecione **Exportar todos**.
3. Defina o prefixo do nome do arquivo, se desejar.
4. Selecione um ou mais formatos de exportação.
5. Toque no botão **Exportar**.

!!! tip

    Para especificações detalhadas de colunas e regras de geração de arquivos (como quando múltiplos arquivos são gerados por exportação), consulte [Formatos de Exportação](export-formats.md).

## Buscar e Filtrar Ninhos

Use a barra de busca para encontrar ninhos por:

- Número de campo  
- Espécie  
- Localidade  

Os filtros permitem restringir os resultados por:

- Ativo / inativo  
- Espécie  
- Localidade  
- Data  
- Destino do ninho  
- Observador  

## Ordenar Ninhos

Toque no **ícone de ordenação** para ordenar os ninhos por:

- Número de campo  
- Espécie  
- Localidade  
- Data de descoberta  
- Última data  
- Destino do ninho  

A ordenação ajuda a manter grandes conjuntos de monitoramento organizados.

---

Gerenciar ninhos no Xolmis Mobile oferece um fluxo de trabalho eficiente para documentar descobertas de ninhos e manter registros reprodutivos precisos ao longo do trabalho de campo.

*[CSV]: Comma Separated Values  
*[JSON]: JavaScript Object Notation  
*[KML]: Keyhole Markup Language
