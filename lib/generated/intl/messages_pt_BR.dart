// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a pt_BR locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'pt_BR';

  static String m0(howMany, gender, what) =>
      "Tem certeza que deseja excluir ${Intl.plural(howMany, one: '${Intl.gender(gender, female: 'esta', male: 'este', other: 'este(a)')}', other: '${Intl.gender(gender, female: 'estas', male: 'estes', other: 'estes(as)')}')} ${what}?";

  static String m1(speciesName) =>
      "Deseja remover a espécie ${speciesName} dos outros inventários ativos?";

  static String m2(howMany) =>
      "${Intl.plural(howMany, one: 'Ovo', other: 'Ovos')}";

  static String m3(howMany, errorMessage) =>
      "Erro ao exportar ${Intl.plural(howMany, one: 'o inventário', other: 'os inventários')}: ${errorMessage}";

  static String m4(howMany, errorMessage) =>
      "Erro ao exportar ${Intl.plural(howMany, one: 'o ninho', other: 'os ninhos')}: ${errorMessage}";

  static String m5(howMany, errorMessage) =>
      "Erro ao exportar ${Intl.plural(howMany, one: 'o espécime', other: 'os espécimes')}: ${errorMessage}";

  static String m6(errorMessage) =>
      "Erro ao desativar o ninho: ${errorMessage}";

  static String m7(what) => "Exportar todos os ${what}";

  static String m8(what) => "Exportar ${what}";

  static String m9(howMany) =>
      "${Intl.plural(howMany, one: 'Imagem', other: 'Imagens')}";

  static String m10(howMany) =>
      "${Intl.plural(howMany, one: 'indivíduo', other: 'indivíduos')}";

  static String m11(howMany) =>
      "${Intl.plural(howMany, one: 'inventário', other: 'inventários')}";

  static String m12(howMany) =>
      "${Intl.plural(howMany, one: 'Dados do inventário', other: 'Dados dos inventários')}";

  static String m13(howMany) =>
      "${Intl.plural(howMany, one: '1 minuto', other: '${howMany} minutos')} de duração";

  static String m14(howMany) =>
      "${Intl.plural(howMany, one: 'Inventário exportado!', other: 'Inventários exportados!')}";

  static String m15(howMany) =>
      "${Intl.plural(howMany, one: 'inventário encontrado', other: 'inventários encontrados')}";

  static String m16(howMany) =>
      "${Intl.plural(howMany, one: 'Nota do diário', other: 'Notas do diário')}";

  static String m17(howMany) =>
      "${Intl.plural(howMany, one: 'minuto', other: 'minutos')}";

  static String m18(howMany) =>
      "${Intl.plural(howMany, one: 'ninho', other: 'ninhos')}";

  static String m19(howMany) =>
      "${Intl.plural(howMany, one: 'Dados do ninho', other: 'Dados dos ninhos')}";

  static String m20(howMany) =>
      "${Intl.plural(howMany, one: 'Ninho exportado!', other: 'Ninhos exportados!')}";

  static String m21(howMany) =>
      "${Intl.plural(howMany, one: 'Ninhego', other: 'Ninhegos')}";

  static String m22(howMany) =>
      "${Intl.plural(howMany, one: 'Revisão', other: 'Revisões')}";

  static String m23(howMany) =>
      "${Intl.plural(howMany, one: 'Espécie', other: 'Espécies')}";

  static String m24(howMany) =>
      "${Intl.plural(howMany, one: 'sp.', other: 'spp.')}";

  static String m25(howMany) =>
      "${Intl.plural(howMany, zero: 'espécies', one: 'espécie', other: 'espécies')}";

  static String m26(howMany) =>
      "${Intl.plural(howMany, one: '1 espécie', other: '${howMany} espécies')} por lista";

  static String m27(howMany) =>
      "${Intl.plural(howMany, one: 'Dados do espécime', other: 'Dados dos espécimes')}";

  static String m28(howMany) =>
      "${Intl.plural(howMany, one: 'Espécime exportado!', other: 'Espécimes exportados!')}";

  static String m29(howMany) =>
      "${Intl.plural(howMany, one: 'Espécime', other: 'Espécimes')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("Sobre o app"),
        "active": MessageLookupByLibrary.simpleMessage("Ativos"),
        "addEgg": MessageLookupByLibrary.simpleMessage("Adicionar ovo"),
        "addImage": MessageLookupByLibrary.simpleMessage("Adicionar imagem"),
        "addPoi": MessageLookupByLibrary.simpleMessage("Adicionar POI"),
        "addSpecies": MessageLookupByLibrary.simpleMessage("Adicionar espécie"),
        "addSpeciesToSample":
            MessageLookupByLibrary.simpleMessage("Incluir na amostra"),
        "appearance": MessageLookupByLibrary.simpleMessage("Aparência"),
        "camera": MessageLookupByLibrary.simpleMessage("Câmera"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "clearSelection":
            MessageLookupByLibrary.simpleMessage("Limpar seleção"),
        "close": MessageLookupByLibrary.simpleMessage("Fechar"),
        "cloudCover": MessageLookupByLibrary.simpleMessage("Nebulosidade"),
        "confirmAutoFinishMessage": MessageLookupByLibrary.simpleMessage(
            "Inventário automaticamente encerrado. Você deseja mantê-lo ativo ou finalizar este inventário?"),
        "confirmDelete":
            MessageLookupByLibrary.simpleMessage("Confirmar exclusão"),
        "confirmDeleteMessage": m0,
        "confirmDeleteSpecies":
            MessageLookupByLibrary.simpleMessage("Remover espécie"),
        "confirmDeleteSpeciesMessage": m1,
        "confirmFate":
            MessageLookupByLibrary.simpleMessage("Confirmar destino"),
        "confirmFinish":
            MessageLookupByLibrary.simpleMessage("Confirmar encerramento"),
        "confirmFinishMessage": MessageLookupByLibrary.simpleMessage(
            "Tem certeza que deseja encerrar este inventário?"),
        "count": MessageLookupByLibrary.simpleMessage("Contagem"),
        "dangerZone": MessageLookupByLibrary.simpleMessage("Área perigosa"),
        "darkMode": MessageLookupByLibrary.simpleMessage("Escuro"),
        "dataDeleted": MessageLookupByLibrary.simpleMessage(
            "Dados do aplicativo apagados com sucesso!"),
        "decreaseIndividuals": MessageLookupByLibrary.simpleMessage(
            "Diminuir contagem de indivíduos"),
        "delete": MessageLookupByLibrary.simpleMessage("Apagar"),
        "deleteAppData":
            MessageLookupByLibrary.simpleMessage("Apagar dados do aplicativo"),
        "deleteAppDataDescription": MessageLookupByLibrary.simpleMessage(
            "Todos os dados serão apagados. Use com cautela! Esta ação não poderá ser desfeita."),
        "deleteData": MessageLookupByLibrary.simpleMessage("Apagar dados"),
        "deleteDataMessage": MessageLookupByLibrary.simpleMessage(
            "Tem certeza que deseja apagar todos os dados do aplicativo? Esta ação não poderá ser desfeita."),
        "deleteEgg": MessageLookupByLibrary.simpleMessage("Apagar ovo"),
        "deleteImage": MessageLookupByLibrary.simpleMessage("Apagar imagem"),
        "deleteInventory":
            MessageLookupByLibrary.simpleMessage("Apagar inventário"),
        "deleteJournalEntry":
            MessageLookupByLibrary.simpleMessage("Apagar nota"),
        "deleteNest": MessageLookupByLibrary.simpleMessage("Apagar ninho"),
        "deletePoi": MessageLookupByLibrary.simpleMessage("Apagar POI"),
        "deleteRevision":
            MessageLookupByLibrary.simpleMessage("Apagar revisão de ninho"),
        "deleteSpecies": MessageLookupByLibrary.simpleMessage("Apagar espécie"),
        "deleteSpecimen":
            MessageLookupByLibrary.simpleMessage("Apagar espécime"),
        "deleteVegetation": MessageLookupByLibrary.simpleMessage(
            "Apagar registro de vegetação"),
        "deleteWeather":
            MessageLookupByLibrary.simpleMessage("Apagar registro do tempo"),
        "distribution": MessageLookupByLibrary.simpleMessage("Distribuição"),
        "distributionContinuousCoverWithGaps":
            MessageLookupByLibrary.simpleMessage(
                "Contínua com manchas sem cobertura"),
        "distributionContinuousDenseCover":
            MessageLookupByLibrary.simpleMessage("Contínua e densa"),
        "distributionContinuousDenseCoverWithEdge":
            MessageLookupByLibrary.simpleMessage(
                "Contínua com borda separando estratos"),
        "distributionFewPatches":
            MessageLookupByLibrary.simpleMessage("Poucas manchas"),
        "distributionFewPatchesSparseIndividuals":
            MessageLookupByLibrary.simpleMessage(
                "Poucas manchas e indivíduos isolados"),
        "distributionFewSparseIndividuals":
            MessageLookupByLibrary.simpleMessage("Poucos indivíduos esparsos"),
        "distributionHighDensityIndividuals":
            MessageLookupByLibrary.simpleMessage(
                "Indivíduos isolados em alta densidade"),
        "distributionManyPatches": MessageLookupByLibrary.simpleMessage(
            "Várias manchas equidistantes"),
        "distributionManyPatchesSparseIndividuals":
            MessageLookupByLibrary.simpleMessage(
                "Várias manchas e indivíduos dispersos"),
        "distributionManySparseIndividuals":
            MessageLookupByLibrary.simpleMessage("Vários indivíduos esparsos"),
        "distributionNone": MessageLookupByLibrary.simpleMessage("Nada"),
        "distributionOnePatch":
            MessageLookupByLibrary.simpleMessage("Uma mancha"),
        "distributionOnePatchFewSparseIndividuals":
            MessageLookupByLibrary.simpleMessage(
                "Uma mancha e indivíduos isolados"),
        "distributionOnePatchManySparseIndividuals":
            MessageLookupByLibrary.simpleMessage(
                "Mancha e vários indivíduos isolados"),
        "distributionRare": MessageLookupByLibrary.simpleMessage("Rara"),
        "duration": MessageLookupByLibrary.simpleMessage("Duração"),
        "durationMin": MessageLookupByLibrary.simpleMessage("Duração (min)"),
        "editCount": MessageLookupByLibrary.simpleMessage("Editar contagem"),
        "editEgg": MessageLookupByLibrary.simpleMessage("Editar ovo"),
        "editImageNotes":
            MessageLookupByLibrary.simpleMessage("Editar notas da imagem"),
        "editInventoryId": MessageLookupByLibrary.simpleMessage("Editar ID"),
        "editJournalEntry": MessageLookupByLibrary.simpleMessage("Editar nota"),
        "editNest": MessageLookupByLibrary.simpleMessage("Editar ninho"),
        "editNestRevision":
            MessageLookupByLibrary.simpleMessage("Editar revisão de ninho"),
        "editNotes": MessageLookupByLibrary.simpleMessage("Editar notas"),
        "editSpecimen": MessageLookupByLibrary.simpleMessage("Editar espécime"),
        "editVegetation":
            MessageLookupByLibrary.simpleMessage("Editar dados de vegetação"),
        "editWeather":
            MessageLookupByLibrary.simpleMessage("Editar dados do tempo"),
        "egg": m2,
        "eggShape": MessageLookupByLibrary.simpleMessage("Forma do ovo"),
        "eggShapeBiconical": MessageLookupByLibrary.simpleMessage("Bicônico"),
        "eggShapeConical": MessageLookupByLibrary.simpleMessage("Cônico"),
        "eggShapeCylindrical":
            MessageLookupByLibrary.simpleMessage("Cilíndrico"),
        "eggShapeElliptical": MessageLookupByLibrary.simpleMessage("Elíptico"),
        "eggShapeLongitudinal":
            MessageLookupByLibrary.simpleMessage("Longitudinal"),
        "eggShapeOval": MessageLookupByLibrary.simpleMessage("Oval"),
        "eggShapePyriform": MessageLookupByLibrary.simpleMessage("Piriforme"),
        "eggShapeSpherical": MessageLookupByLibrary.simpleMessage("Esférico"),
        "errorEggAlreadyExists": MessageLookupByLibrary.simpleMessage(
            "Já existe um ovo com este número de campo."),
        "errorExportingInventory": m3,
        "errorExportingNest": m4,
        "errorExportingSpecimen": m5,
        "errorGettingLocation": MessageLookupByLibrary.simpleMessage(
            "Erro ao obter a localização."),
        "errorImportingInventory": MessageLookupByLibrary.simpleMessage(
            "Erro ao importar inventário."),
        "errorInactivatingNest": m6,
        "errorInsertingInventory":
            MessageLookupByLibrary.simpleMessage("Erro ao inserir inventário."),
        "errorNestAlreadyExists": MessageLookupByLibrary.simpleMessage(
            "Já existe um ninho com este número de campo."),
        "errorSavingEgg":
            MessageLookupByLibrary.simpleMessage("Erro ao salvar o ovo."),
        "errorSavingJournalEntry": MessageLookupByLibrary.simpleMessage(
            "Erro ao salvar a nota do diário de campo"),
        "errorSavingNest":
            MessageLookupByLibrary.simpleMessage("Erro ao salvar o ninho."),
        "errorSavingRevision": MessageLookupByLibrary.simpleMessage(
            "Erro ao salvar a revisão de ninho."),
        "errorSavingSpecimen":
            MessageLookupByLibrary.simpleMessage("Erro ao salvar o espécime."),
        "errorSavingVegetation": MessageLookupByLibrary.simpleMessage(
            "Erro ao salvar os dados de vegetação"),
        "errorSavingWeather": MessageLookupByLibrary.simpleMessage(
            "Erro ao salvar os dados do tempo"),
        "errorSpeciesAlreadyExists": MessageLookupByLibrary.simpleMessage(
            "Espécie já adicionada à lista"),
        "errorSpecimenAlreadyExists": MessageLookupByLibrary.simpleMessage(
            "Já existe um espécime com este número de campo."),
        "export": MessageLookupByLibrary.simpleMessage("Exportar"),
        "exportAll": MessageLookupByLibrary.simpleMessage("Exportar todos"),
        "exportAllWhat": m7,
        "exportWhat": m8,
        "female": MessageLookupByLibrary.simpleMessage("Fêmea"),
        "fieldJournal": MessageLookupByLibrary.simpleMessage("Diário de campo"),
        "fieldNumber": MessageLookupByLibrary.simpleMessage("Número de campo"),
        "findInventories":
            MessageLookupByLibrary.simpleMessage("Procurar inventários..."),
        "findJournalEntries":
            MessageLookupByLibrary.simpleMessage("Procurar notas"),
        "findNests": MessageLookupByLibrary.simpleMessage("Procurar ninhos..."),
        "findSpecies": MessageLookupByLibrary.simpleMessage("Buscar espécie"),
        "findSpecimens":
            MessageLookupByLibrary.simpleMessage("Procurar espécimes..."),
        "finish": MessageLookupByLibrary.simpleMessage("Encerrar"),
        "finishInventory":
            MessageLookupByLibrary.simpleMessage("Encerrar inventário"),
        "finished": MessageLookupByLibrary.simpleMessage("Encerrados"),
        "formatNumbers":
            MessageLookupByLibrary.simpleMessage("Formatar números"),
        "gallery": MessageLookupByLibrary.simpleMessage("Galeria"),
        "general": MessageLookupByLibrary.simpleMessage("Geral"),
        "generateId": MessageLookupByLibrary.simpleMessage("Gerar ID"),
        "height": MessageLookupByLibrary.simpleMessage("Altura"),
        "heightAboveGround":
            MessageLookupByLibrary.simpleMessage("Altura acima do solo"),
        "helpers": MessageLookupByLibrary.simpleMessage("Ajudantes de ninho"),
        "herbs": MessageLookupByLibrary.simpleMessage("Herbáceas"),
        "host": MessageLookupByLibrary.simpleMessage("Hospedeiro"),
        "imageDetails":
            MessageLookupByLibrary.simpleMessage("Detalhes da imagem"),
        "images": m9,
        "import": MessageLookupByLibrary.simpleMessage("Importar"),
        "importingInventory":
            MessageLookupByLibrary.simpleMessage("Importando inventário..."),
        "inactive": MessageLookupByLibrary.simpleMessage("Inativos"),
        "increaseIndividuals": MessageLookupByLibrary.simpleMessage(
            "Aumentar contagem de indivíduos"),
        "individual": m10,
        "individualsCount":
            MessageLookupByLibrary.simpleMessage("Contagem de indivíduos"),
        "individualsCounted":
            MessageLookupByLibrary.simpleMessage("Número de indivíduos"),
        "insertDuration":
            MessageLookupByLibrary.simpleMessage("Insira uma duração"),
        "insertFieldNumber": MessageLookupByLibrary.simpleMessage(
            "Por favor, insira o número de campo"),
        "insertHeight": MessageLookupByLibrary.simpleMessage("Insira a altura"),
        "insertInventoryId": MessageLookupByLibrary.simpleMessage(
            "Por favor, insira uma ID para o inventário"),
        "insertLocality": MessageLookupByLibrary.simpleMessage(
            "Por favor, insira o nome da localidade"),
        "insertMaxSpecies":
            MessageLookupByLibrary.simpleMessage("Insira o máximo de espécies"),
        "insertNestSupport": MessageLookupByLibrary.simpleMessage(
            "Por favor, insira o suporte do ninho"),
        "insertProportion":
            MessageLookupByLibrary.simpleMessage("Insira a proporção"),
        "insertTitle": MessageLookupByLibrary.simpleMessage(
            "Insira um título para a nota"),
        "intervaledQualitativeLists": MessageLookupByLibrary.simpleMessage(
            "Listas qualitativas por intervalo"),
        "inventories": MessageLookupByLibrary.simpleMessage("Inventários"),
        "inventory": m11,
        "inventoryBanding": MessageLookupByLibrary.simpleMessage("Anilhamento"),
        "inventoryCasual":
            MessageLookupByLibrary.simpleMessage("Observação Casual"),
        "inventoryData": m12,
        "inventoryDuration": m13,
        "inventoryExported": m14,
        "inventoryFound": m15,
        "inventoryFreeQualitative":
            MessageLookupByLibrary.simpleMessage("Lista Qualitativa Livre"),
        "inventoryId": MessageLookupByLibrary.simpleMessage("ID do Inventário"),
        "inventoryIdAlreadyExists": MessageLookupByLibrary.simpleMessage(
            "Já existe um inventário com esta ID."),
        "inventoryImportedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Inventário importado com sucesso!"),
        "inventoryIntervalQualitative": MessageLookupByLibrary.simpleMessage(
            "Lista Qualitativa por Intervalos"),
        "inventoryMackinnonList":
            MessageLookupByLibrary.simpleMessage("Lista de Mackinnon"),
        "inventoryPointCount":
            MessageLookupByLibrary.simpleMessage("Ponto de Contagem"),
        "inventoryTimedQualitative": MessageLookupByLibrary.simpleMessage(
            "Lista Qualitativa Temporizada"),
        "inventoryTransectionCount":
            MessageLookupByLibrary.simpleMessage("Contagem em Transecção"),
        "inventoryType":
            MessageLookupByLibrary.simpleMessage("Tipo de inventário"),
        "journalEntries": m16,
        "keepRunning": MessageLookupByLibrary.simpleMessage("Manter ativo"),
        "length": MessageLookupByLibrary.simpleMessage("Comprimento"),
        "lightMode": MessageLookupByLibrary.simpleMessage("Claro"),
        "listFinished": MessageLookupByLibrary.simpleMessage("Lista concluída"),
        "listFinishedMessage": MessageLookupByLibrary.simpleMessage(
            "A lista atingiu o número máximo de espécies. Deseja iniciar a próxima lista ou encerrar?"),
        "locality": MessageLookupByLibrary.simpleMessage("Localidade"),
        "mackinnonLists":
            MessageLookupByLibrary.simpleMessage("Listas de Mackinnon"),
        "male": MessageLookupByLibrary.simpleMessage("Macho"),
        "maxSpecies": MessageLookupByLibrary.simpleMessage("Máx. espécies"),
        "minutes": m17,
        "mustBeBiggerThanFive":
            MessageLookupByLibrary.simpleMessage("Deve ser maior ou igual a 5"),
        "nest": m18,
        "nestData": m19,
        "nestExported": m20,
        "nestFate": MessageLookupByLibrary.simpleMessage("Destino do ninho"),
        "nestInfo":
            MessageLookupByLibrary.simpleMessage("Informações do ninho"),
        "nestPhase": MessageLookupByLibrary.simpleMessage("Estágio"),
        "nestRevision":
            MessageLookupByLibrary.simpleMessage("Revisão de ninho"),
        "nestStageBuilding": MessageLookupByLibrary.simpleMessage("Construção"),
        "nestStageHatching": MessageLookupByLibrary.simpleMessage("Eclosão"),
        "nestStageInactive": MessageLookupByLibrary.simpleMessage("Inativo"),
        "nestStageIncubating":
            MessageLookupByLibrary.simpleMessage("Incubação"),
        "nestStageLaying": MessageLookupByLibrary.simpleMessage("Postura"),
        "nestStageNestling": MessageLookupByLibrary.simpleMessage("Ninhego"),
        "nestStageUnknown":
            MessageLookupByLibrary.simpleMessage("Indeterminado"),
        "nestStatus": MessageLookupByLibrary.simpleMessage("Status do ninho"),
        "nestStatusActive": MessageLookupByLibrary.simpleMessage("Ativo"),
        "nestStatusInactive": MessageLookupByLibrary.simpleMessage("Inativo"),
        "nestStatusUnknown":
            MessageLookupByLibrary.simpleMessage("Indeterminado"),
        "nestSupport": MessageLookupByLibrary.simpleMessage("Suporte do ninho"),
        "nestling": m21,
        "nests": MessageLookupByLibrary.simpleMessage("Ninhos"),
        "newInventory": MessageLookupByLibrary.simpleMessage("Novo inventário"),
        "newJournalEntry": MessageLookupByLibrary.simpleMessage("Nova nota"),
        "newNest": MessageLookupByLibrary.simpleMessage("Novo ninho"),
        "newPoi": MessageLookupByLibrary.simpleMessage("Novo POI"),
        "newSpecimen": MessageLookupByLibrary.simpleMessage("Novo espécime"),
        "nidoparasite": MessageLookupByLibrary.simpleMessage("Nidoparasita"),
        "no": MessageLookupByLibrary.simpleMessage("Não"),
        "noDataAvailable":
            MessageLookupByLibrary.simpleMessage("Dados não disponíveis."),
        "noEggsFound":
            MessageLookupByLibrary.simpleMessage("Nenhum ovo registrado."),
        "noFileSelected":
            MessageLookupByLibrary.simpleMessage("Nenhum arquivo selecionado."),
        "noImagesFound":
            MessageLookupByLibrary.simpleMessage("Nenhuma imagem encontrada."),
        "noInventoriesFound": MessageLookupByLibrary.simpleMessage(
            "Nenhum inventário encontrado."),
        "noJournalEntriesFound":
            MessageLookupByLibrary.simpleMessage("Nenhuma nota encontrada"),
        "noNestsFound":
            MessageLookupByLibrary.simpleMessage("Nenhum ninho encontrado."),
        "noPoiFound":
            MessageLookupByLibrary.simpleMessage("Nenhum POI encontrado."),
        "noRevisionsFound":
            MessageLookupByLibrary.simpleMessage("Nenhuma revisão registrada."),
        "noSpeciesFound":
            MessageLookupByLibrary.simpleMessage("Nenhuma espécie registrada"),
        "noSpecimenCollected":
            MessageLookupByLibrary.simpleMessage("Nenhum espécime coletado."),
        "noVegetationFound": MessageLookupByLibrary.simpleMessage(
            "Nenhum registro de vegetação"),
        "noWeatherFound":
            MessageLookupByLibrary.simpleMessage("Nenhum registro do tempo"),
        "notes": MessageLookupByLibrary.simpleMessage("Observações"),
        "observer": MessageLookupByLibrary.simpleMessage("Observador"),
        "observerSetting":
            MessageLookupByLibrary.simpleMessage("Observador (sigla)"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "optional": MessageLookupByLibrary.simpleMessage("* opcional"),
        "outOfSample": MessageLookupByLibrary.simpleMessage("Fora da amostra"),
        "pause": MessageLookupByLibrary.simpleMessage("Pausa"),
        "perSpecies": MessageLookupByLibrary.simpleMessage("Por espécie"),
        "permissionDenied":
            MessageLookupByLibrary.simpleMessage("Permissão negada."),
        "permissionDeniedPermanently": MessageLookupByLibrary.simpleMessage(
            "Permissão negada permanentemente."),
        "philornisLarvaePresent": MessageLookupByLibrary.simpleMessage(
            "Presença de larvas de Philornis"),
        "poi": MessageLookupByLibrary.simpleMessage("POI"),
        "pointCounts":
            MessageLookupByLibrary.simpleMessage("Pontos de contagem"),
        "precipitation": MessageLookupByLibrary.simpleMessage("Precipitação"),
        "precipitationDrizzle": MessageLookupByLibrary.simpleMessage("Garoa"),
        "precipitationFog": MessageLookupByLibrary.simpleMessage("Névoa"),
        "precipitationMist": MessageLookupByLibrary.simpleMessage("Neblina"),
        "precipitationNone": MessageLookupByLibrary.simpleMessage("Nenhuma"),
        "precipitationRain": MessageLookupByLibrary.simpleMessage("Chuva"),
        "proportion": MessageLookupByLibrary.simpleMessage("Proporção"),
        "reactivateInventory":
            MessageLookupByLibrary.simpleMessage("Reativar inventário"),
        "recordTime": MessageLookupByLibrary.simpleMessage("Hora do registro"),
        "recordsPerMonth":
            MessageLookupByLibrary.simpleMessage("Registros por mês"),
        "refreshList": MessageLookupByLibrary.simpleMessage("Atualizar"),
        "removeSpeciesFromSample":
            MessageLookupByLibrary.simpleMessage("Remover da amostra"),
        "reportSpeciesByInventory":
            MessageLookupByLibrary.simpleMessage("Espécies por inventário"),
        "requiredField": MessageLookupByLibrary.simpleMessage("* obrigatório"),
        "resume": MessageLookupByLibrary.simpleMessage("Retomar"),
        "revision": m22,
        "save": MessageLookupByLibrary.simpleMessage("Salvar"),
        "selectInventoryType": MessageLookupByLibrary.simpleMessage(
            "Por favor, selecione um tipo de inventário"),
        "selectMode": MessageLookupByLibrary.simpleMessage("Selecione o modo"),
        "selectPrecipitation":
            MessageLookupByLibrary.simpleMessage("Selecione uma precipitação"),
        "selectSpecies": MessageLookupByLibrary.simpleMessage(
            "Por favor, selecione uma espécie"),
        "selectSpeciesToShowStats": MessageLookupByLibrary.simpleMessage(
            "Selecione uma espécie para ver as estatísticas"),
        "settings": MessageLookupByLibrary.simpleMessage("Configurações"),
        "shareImage":
            MessageLookupByLibrary.simpleMessage("Compartilhar imagem"),
        "shrubs": MessageLookupByLibrary.simpleMessage("Arbustos"),
        "simultaneousInventories":
            MessageLookupByLibrary.simpleMessage("Inventários simultâneos"),
        "simultaneousLimitReached": MessageLookupByLibrary.simpleMessage(
            "Limite de inventários simultâneos atingido."),
        "sortAscending":
            MessageLookupByLibrary.simpleMessage("Ordem crescente"),
        "sortByLastModified": MessageLookupByLibrary.simpleMessage(
            "Ordenar por última modificação"),
        "sortByName": MessageLookupByLibrary.simpleMessage("Ordenar por nome"),
        "sortByTime": MessageLookupByLibrary.simpleMessage("Ordenar por tempo"),
        "sortByTitle":
            MessageLookupByLibrary.simpleMessage("Ordenar por título"),
        "sortDescending":
            MessageLookupByLibrary.simpleMessage("Ordem decrescente"),
        "species": m23,
        "speciesAccumulated":
            MessageLookupByLibrary.simpleMessage("Acumulado de espécies"),
        "speciesAccumulationCurve": MessageLookupByLibrary.simpleMessage(
            "Curva de acumulação de espécies"),
        "speciesAcronym": m24,
        "speciesCount": m25,
        "speciesCounted":
            MessageLookupByLibrary.simpleMessage("Número de espécies"),
        "speciesInfo":
            MessageLookupByLibrary.simpleMessage("Informações da espécie"),
        "speciesName": MessageLookupByLibrary.simpleMessage("Nome da espécie"),
        "speciesNotes":
            MessageLookupByLibrary.simpleMessage("Anotações da espécie"),
        "speciesPerList": m26,
        "speciesPerListTitle":
            MessageLookupByLibrary.simpleMessage("Espécies por lista"),
        "specimenBlood": MessageLookupByLibrary.simpleMessage("Sangue"),
        "specimenBones": MessageLookupByLibrary.simpleMessage("Ossos"),
        "specimenClaw": MessageLookupByLibrary.simpleMessage("Garra"),
        "specimenData": m27,
        "specimenEgg": MessageLookupByLibrary.simpleMessage("Ovo"),
        "specimenExported": m28,
        "specimenFeathers": MessageLookupByLibrary.simpleMessage("Penas"),
        "specimenFeces": MessageLookupByLibrary.simpleMessage("Fezes"),
        "specimenNest": MessageLookupByLibrary.simpleMessage("Ninho"),
        "specimenParasites": MessageLookupByLibrary.simpleMessage("Parasitas"),
        "specimenPartialCarcass":
            MessageLookupByLibrary.simpleMessage("Carcaça parcial"),
        "specimenRegurgite": MessageLookupByLibrary.simpleMessage("Regurgito"),
        "specimenSwab": MessageLookupByLibrary.simpleMessage("Swab"),
        "specimenTissues": MessageLookupByLibrary.simpleMessage("Tecidos"),
        "specimenType":
            MessageLookupByLibrary.simpleMessage("Tipo de espécime"),
        "specimenWholeCarcass":
            MessageLookupByLibrary.simpleMessage("Carcaça inteira"),
        "specimens": m29,
        "startInventory":
            MessageLookupByLibrary.simpleMessage("Iniciar inventário"),
        "startNextList":
            MessageLookupByLibrary.simpleMessage("Iniciar próxima lista"),
        "statistics": MessageLookupByLibrary.simpleMessage("Estatísticas"),
        "systemMode": MessageLookupByLibrary.simpleMessage("Tema do sistema"),
        "temperature": MessageLookupByLibrary.simpleMessage("Temperatura"),
        "timeFound":
            MessageLookupByLibrary.simpleMessage("Data e hora de encontro"),
        "timeMinutes": MessageLookupByLibrary.simpleMessage(
            "Tempo (intervalos de 10 minutos)"),
        "timedQualitativeLists": MessageLookupByLibrary.simpleMessage(
            "Listas qualitativas temporizadas"),
        "title": MessageLookupByLibrary.simpleMessage("Título"),
        "totalIndividuals":
            MessageLookupByLibrary.simpleMessage("Total de indivíduos"),
        "totalRecords":
            MessageLookupByLibrary.simpleMessage("Total de registros"),
        "totalSpecies":
            MessageLookupByLibrary.simpleMessage("Total de espécies"),
        "trees": MessageLookupByLibrary.simpleMessage("Árvores"),
        "vegetation": MessageLookupByLibrary.simpleMessage("Vegetação"),
        "vegetationData":
            MessageLookupByLibrary.simpleMessage("Dados de vegetação"),
        "weather": MessageLookupByLibrary.simpleMessage("Tempo"),
        "weatherData": MessageLookupByLibrary.simpleMessage("Dados do tempo"),
        "weatherRecord":
            MessageLookupByLibrary.simpleMessage("registro do tempo"),
        "weight": MessageLookupByLibrary.simpleMessage("Peso"),
        "width": MessageLookupByLibrary.simpleMessage("Largura"),
        "windSpeed": MessageLookupByLibrary.simpleMessage("Vento"),
        "windSpeedRangeError":
            MessageLookupByLibrary.simpleMessage("Deve estar entre 0 e 12 bft"),
        "withinSample":
            MessageLookupByLibrary.simpleMessage("Dentro da amostra"),
        "yes": MessageLookupByLibrary.simpleMessage("Sim")
      };
}
