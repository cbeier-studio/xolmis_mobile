# FAQ — Perguntas Frequentes

Esta seção responde às perguntas mais comuns sobre o uso do **Xolmis Mobile** em campo, gerenciamento de dados e resolução de problemas típicos.

## Geral

### O que é o Xolmis Mobile?

O Xolmis Mobile é o aplicativo de coleta de dados de campo que complementa o Xolmis Desktop. Ele permite registrar inventários, ninhos, espécimes e anotações de campo de forma rápida e offline durante o trabalho de campo.

### Preciso de acesso à internet para usar o aplicativo?

Não. O Xolmis Mobile funciona totalmente offline. A internet é necessária apenas para instalar o app, atualizá-lo ou compartilhar arquivos exportados.

### O Xolmis Mobile é gratuito?

Sim. O aplicativo é gratuito e de código aberto.

## Instalação e Configuração

### Por que o app pede permissões de GPS, câmera ou notificações?

- **GPS**: para registrar coordenadas em inventários, POIs de espécies, ninhos, espécimes e anotações do diário.  
- **Câmera/Fotos**: para anexar imagens aos registros.  
- **Notificações**: para alertar quando inventários temporizados forem concluídos automaticamente.

### O app diz que preciso definir uma abreviação de observador. Por quê?

A abreviação do observador é necessária para gerar:

- IDs de inventário  
- Números de campo de ninhos  
- Números de campo de espécimes  

Sem ela, você não pode criar novos registros.

## Inventários

### Por que não consigo adicionar mais espécies à minha lista?

Possivelmente você atingiu o **limite máximo de espécies** (Mackinnon ou limite personalizado).

### Por que meu inventário terminou automaticamente?

Dependendo do método:

- Listas temporizadas terminam quando o cronômetro chega a zero.  
- Listas por intervalos terminam após três intervalos consecutivos sem novas espécies.  
- Pontos de escuta e métodos temporizados terminam quando sua duração expira.

### Por que algumas espécies aparecem em cinza?

Espécies em cinza estão **fora da amostra**, ou seja, foram adicionadas após o término do inventário.

## Busca de Espécies

### Por que não encontro uma espécie na lista de busca?

Possíveis razões:

- A espécie não está incluída na **lista do país** selecionado.  
- A taxonomia ou checklist pode estar desatualizada ou incompleta.  
- Você digitou poucos caracteres.

Você sempre pode adicionar um **nome de espécie personalizado temporário** usando a opção “Adicionar espécie”.

## Ninhos e Espécimes

### Por que não consigo inativar um ninho?

Um ninho deve ter **pelo menos uma revisão** antes de poder ser marcado como inativo.

### Por que o número de campo não foi gerado?

Verifique se:

- A **abreviação do observador** está definida.  
- A data é válida.  
- O tipo de registro suporta numeração automática.

## Diário de Campo

### Posso adicionar imagens ou coordenadas a uma anotação?

Sim. Você pode anexar fotos e opcionalmente adicionar coordenadas GPS a qualquer nota.

## Importação e Exportação

### Quais formatos posso exportar?

Dependendo do módulo:

- **CSV**  
- **Excel** (experimental)  
- **JSON**  
- **KML**  
- **Texto simples** (diário de campo)  
- **Markdown** (diário de campo)

### Como importar dados de outro dispositivo?

Exporte um arquivo JSON do outro dispositivo → abra o Xolmis Mobile → Inventários/Ninhos/Espécimes → menu → **Importar** → selecione o arquivo.

### O que acontece se os registros importados já existirem?

Você pode escolher:

- Sempre perguntar  
- Atualizar registros existentes  
- Ignorar registros existentes  

Esse comportamento é configurável em **Configurações → Importação e Exportação**.

## Backup e Restauração

### Como faço backup dos meus dados?

Vá em **Configurações → Backup → Criar backup**.

Um único arquivo contendo o banco de dados e as imagens será gerado.

### O que acontece ao restaurar um backup?

Todos os dados atuais são **substituídos** pelo backup.

Use essa opção com cuidado.

## Solução de Problemas

### O app está lento ou travando. O que posso fazer?

Tente:

- Fechar e reabrir o app  
- Reiniciar o dispositivo  
- Verificar se está usando a versão mais recente  
- Checar se o armazenamento do dispositivo está cheio  

O Xolmis Mobile limpa arquivos temporários automaticamente ao iniciar.

### O GPS não está funcionando. Como corrigir?

- Verifique se a permissão de localização está ativada  
- Ative o GPS no dispositivo  
- Vá para uma área aberta  
- Se ainda falhar, você pode **inserir coordenadas manualmente**

### Por que a tela ficou em branco após excluir algo?

Isso era um problema conhecido em versões iniciais e já foi corrigido.

Atualize para a versão mais recente.

## Dados e Privacidade

### Onde meus dados são armazenados?

Todos os dados são armazenados **localmente no seu dispositivo**.

Nada é enviado automaticamente.

### O app compartilha meus dados com alguém?

Não. Você decide quando e como exportar ou compartilhar arquivos.

## Integração com o Xolmis Desktop

### Como transferir dados para o Xolmis Desktop?

1. Exporte inventários/ninhos/espécimes do Mobile (JSON recomendado).  
2. Abra o Xolmis Desktop.  
3. Use **Arquivo → Importar → Importar do Xolmis Mobile**.  
4. Revise e valide os registros importados.

### Preciso do Xolmis Desktop para usar o app Mobile?

Não. O Xolmis Mobile funciona de forma independente, mas o Desktop é recomendado para:

- Armazenamento de longo prazo  
- Validação de dados  
- Análise e geração de relatórios  
