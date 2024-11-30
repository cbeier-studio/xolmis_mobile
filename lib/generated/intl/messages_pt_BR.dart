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

  static String m1(howMany) =>
      "${Intl.plural(howMany, one: 'Ovo', other: 'Ovos')}";

  static String m2(howMany, errorMessage) =>
      "Erro ao exportar ${Intl.plural(howMany, one: 'o inventário', other: 'os inventários')}: ${errorMessage}";

  static String m3(howMany, errorMessage) =>
      "Erro ao exportar ${Intl.plural(howMany, one: 'o ninho', other: 'os ninhos')}: ${errorMessage}";

  static String m4(howMany, errorMessage) =>
      "Erro ao exportar ${Intl.plural(howMany, one: 'o espécime', other: 'os espécimes')}: ${errorMessage}";

  static String m5(errorMessage) =>
      "Erro ao desativar o ninho: ${errorMessage}";

  static String m6(what) => "Exportar ${what}";

  static String m7(what) => "Exportar todos os ${what}";

  static String m8(howMany) =>
      "${Intl.plural(howMany, one: 'Imagem', other: 'Imagens')}";

  static String m9(howMany) =>
      "${Intl.plural(howMany, one: 'indivíduo', other: 'indivíduos')}";

  static String m10(howMany) =>
      "${Intl.plural(howMany, one: 'inventário', other: 'inventários')}";

  static String m11(howMany) =>
      "${Intl.plural(howMany, one: 'Dados do inventário', other: 'Dados dos inventários')}";

  static String m12(howMany) =>
      "${Intl.plural(howMany, one: '1 minuto', other: '${howMany} minutos')} de duração";

  static String m13(howMany) =>
      "${Intl.plural(howMany, one: 'Inventário exportado!', other: 'Inventários exportados!')}";

  static String m14(howMany) =>
      "${Intl.plural(howMany, one: 'minuto', other: 'minutos')}";

  static String m15(howMany) =>
      "${Intl.plural(howMany, one: 'ninho', other: 'ninhos')}";

  static String m16(howMany) =>
      "${Intl.plural(howMany, one: 'Dados do ninho', other: 'Dados dos ninhos')}";

  static String m17(howMany) =>
      "${Intl.plural(howMany, one: 'Ninho exportado!', other: 'Ninhos exportados!')}";

  static String m18(howMany) =>
      "${Intl.plural(howMany, one: 'Ninhego', other: 'Ninhegos')}";

  static String m19(howMany) =>
      "${Intl.plural(howMany, one: 'Revisão', other: 'Revisões')}";

  static String m20(howMany) =>
      "${Intl.plural(howMany, one: 'Espécie', other: 'Espécies')}";

  static String m21(howMany) =>
      "${Intl.plural(howMany, one: 'sp.', other: 'spp.')}";

  static String m22(howMany) =>
      "${Intl.plural(howMany, one: '1 espécie', other: '${howMany} espécies')}";

  static String m23(howMany) =>
      "${Intl.plural(howMany, one: '1 espécie', other: '${howMany} espécies')} por lista";

  static String m24(howMany) =>
      "${Intl.plural(howMany, one: 'Dados do espécime', other: 'Dados dos espécimes')}";

  static String m25(howMany) =>
      "${Intl.plural(howMany, one: 'Espécime exportado!', other: 'Espécimes exportados!')}";

  static String m26(howMany) =>
      "${Intl.plural(howMany, one: 'Espécime', other: 'Espécimes')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("Sobre o app"),
        "active": MessageLookupByLibrary.simpleMessage("Ativos"),
        "addEgg": MessageLookupByLibrary.simpleMessage("Adicionar ovo"),
        "addImage": MessageLookupByLibrary.simpleMessage("Adicionar imagem"),
        "addPoi": MessageLookupByLibrary.simpleMessage("Adicionar POI"),
        "appearance": MessageLookupByLibrary.simpleMessage("Aparência"),
        "camera": MessageLookupByLibrary.simpleMessage("Câmera"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "cloudCover": MessageLookupByLibrary.simpleMessage("Nebulosidade"),
        "confirmDelete":
            MessageLookupByLibrary.simpleMessage("Confirmar exclusão"),
        "confirmDeleteMessage": m0,
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
        "deleteData": MessageLookupByLibrary.simpleMessage("Apagar dados"),
        "deleteDataMessage": MessageLookupByLibrary.simpleMessage(
            "Tem certeza que deseja apagar todos os dados do aplicativo? Esta ação não poderá ser desfeita."),
        "deleteEgg": MessageLookupByLibrary.simpleMessage("Apagar ovo"),
        "deleteImage": MessageLookupByLibrary.simpleMessage("Apagar imagem"),
        "deleteInventory":
            MessageLookupByLibrary.simpleMessage("Apagar inventário"),
        "deleteNest": MessageLookupByLibrary.simpleMessage("Apagar ninho"),
        "deletePoi": MessageLookupByLibrary.simpleMessage("Apagar POI"),
        "deleteRevision":
            MessageLookupByLibrary.simpleMessage("Apagar revisão de ninho"),
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
        "editImageNotes":
            MessageLookupByLibrary.simpleMessage("Editar notas da imagem"),
        "editNotes": MessageLookupByLibrary.simpleMessage("Editar notas"),
        "egg": m1,
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
        "errorExportingInventory": m2,
        "errorExportingNest": m3,
        "errorExportingSpecimen": m4,
        "errorGettingLocation": MessageLookupByLibrary.simpleMessage(
            "Erro ao obter a localização."),
        "errorInactivatingNest": m5,
        "errorInsertingInventory":
            MessageLookupByLibrary.simpleMessage("Erro ao inserir inventário."),
        "errorInsertingVegetation": MessageLookupByLibrary.simpleMessage(
            "Erro ao salvar os dados de vegetação"),
        "errorInsertingWeather": MessageLookupByLibrary.simpleMessage(
            "Erro ao salvar os dados do tempo"),
        "errorNestAlreadyExists": MessageLookupByLibrary.simpleMessage(
            "Já existe um ninho com este número de campo."),
        "errorSavingEgg":
            MessageLookupByLibrary.simpleMessage("Erro ao salvar o ovo."),
        "errorSavingNest":
            MessageLookupByLibrary.simpleMessage("Erro ao salvar o ninho."),
        "errorSavingRevision": MessageLookupByLibrary.simpleMessage(
            "Erro ao salvar a revisão de ninho."),
        "errorSavingSpecimen":
            MessageLookupByLibrary.simpleMessage("Erro ao salvar o espécime."),
        "errorSpecimenAlreadyExists": MessageLookupByLibrary.simpleMessage(
            "Já existe um espécime com este número de campo."),
        "export": m6,
        "exportAll": m7,
        "female": MessageLookupByLibrary.simpleMessage("Fêmea"),
        "fieldNumber": MessageLookupByLibrary.simpleMessage("Número de campo"),
        "findInventories":
            MessageLookupByLibrary.simpleMessage("Procurar inventários..."),
        "findNests": MessageLookupByLibrary.simpleMessage("Procurar ninhos..."),
        "findSpecies": MessageLookupByLibrary.simpleMessage("Buscar espécie"),
        "findSpecimens":
            MessageLookupByLibrary.simpleMessage("Procurar espécimes..."),
        "finish": MessageLookupByLibrary.simpleMessage("Encerrar"),
        "finishInventory":
            MessageLookupByLibrary.simpleMessage("Encerrar inventário"),
        "finished": MessageLookupByLibrary.simpleMessage("Encerrados"),
        "gallery": MessageLookupByLibrary.simpleMessage("Galeria"),
        "generateId": MessageLookupByLibrary.simpleMessage("Gerar ID"),
        "height": MessageLookupByLibrary.simpleMessage("Altura"),
        "heightAboveGround":
            MessageLookupByLibrary.simpleMessage("Altura acima do solo"),
        "helpers": MessageLookupByLibrary.simpleMessage("Ajudantes de ninho"),
        "herbs": MessageLookupByLibrary.simpleMessage("Herbáceas"),
        "host": MessageLookupByLibrary.simpleMessage("Hospedeiro"),
        "imageDetails":
            MessageLookupByLibrary.simpleMessage("Detalhes da imagem"),
        "images": m8,
        "inactive": MessageLookupByLibrary.simpleMessage("Inativos"),
        "increaseIndividuals": MessageLookupByLibrary.simpleMessage(
            "Aumentar contagem de indivíduos"),
        "individual": m9,
        "individualsCount":
            MessageLookupByLibrary.simpleMessage("Contagem de indivíduos"),
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
        "inventories": MessageLookupByLibrary.simpleMessage("Inventários"),
        "inventory": m10,
        "inventoryBanding": MessageLookupByLibrary.simpleMessage("Anilhamento"),
        "inventoryCasual":
            MessageLookupByLibrary.simpleMessage("Observação Casual"),
        "inventoryData": m11,
        "inventoryDuration": m12,
        "inventoryExported": m13,
        "inventoryFreeQualitative":
            MessageLookupByLibrary.simpleMessage("Lista Qualitativa Livre"),
        "inventoryId":
            MessageLookupByLibrary.simpleMessage("ID do Inventário *"),
        "inventoryIdAlreadyExists": MessageLookupByLibrary.simpleMessage(
            "Já existe um inventário com esta ID."),
        "inventoryMackinnonList":
            MessageLookupByLibrary.simpleMessage("Lista de Mackinnon"),
        "inventoryPointCount":
            MessageLookupByLibrary.simpleMessage("Ponto de Contagem"),
        "inventoryTimedQualitative": MessageLookupByLibrary.simpleMessage(
            "Lista Qualitativa Temporizada"),
        "inventoryTransectionCount":
            MessageLookupByLibrary.simpleMessage("Contagem em Transecção"),
        "inventoryType":
            MessageLookupByLibrary.simpleMessage("Tipo de inventário *"),
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
        "minutes": m14,
        "mustBeBiggerThanFive":
            MessageLookupByLibrary.simpleMessage("Deve ser maior ou igual a 5"),
        "nest": m15,
        "nestData": m16,
        "nestExported": m17,
        "nestFate": MessageLookupByLibrary.simpleMessage("Destino do ninho *"),
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
        "nestling": m18,
        "nests": MessageLookupByLibrary.simpleMessage("Ninhos"),
        "newInventory": MessageLookupByLibrary.simpleMessage("Novo inventário"),
        "newNest": MessageLookupByLibrary.simpleMessage("Novo ninho"),
        "newPoi": MessageLookupByLibrary.simpleMessage("Novo POI"),
        "newSpecimen": MessageLookupByLibrary.simpleMessage("Novo espécime"),
        "nidoparasite": MessageLookupByLibrary.simpleMessage("Nidoparasita"),
        "noEggsFound":
            MessageLookupByLibrary.simpleMessage("Nenhum ovo registrado."),
        "noImagesFound":
            MessageLookupByLibrary.simpleMessage("Nenhuma imagem encontrada."),
        "noInventoriesFound": MessageLookupByLibrary.simpleMessage(
            "Nenhum inventário encontrado."),
        "noNestsFound":
            MessageLookupByLibrary.simpleMessage("Nenhum ninho encontrado."),
        "noPoiFound":
            MessageLookupByLibrary.simpleMessage("Nenhum POI encontrado."),
        "noRevisionsFound":
            MessageLookupByLibrary.simpleMessage("Nenhuma revisão registrada."),
        "noSpecimenCollected":
            MessageLookupByLibrary.simpleMessage("Nenhum espécime coletado."),
        "noVegetationFound": MessageLookupByLibrary.simpleMessage(
            "Nenhum registro de vegetação"),
        "noWeatherFound":
            MessageLookupByLibrary.simpleMessage("Nenhum registro do tempo"),
        "notes": MessageLookupByLibrary.simpleMessage("Observações"),
        "observer": MessageLookupByLibrary.simpleMessage("Observador"),
        "observerAcronym":
            MessageLookupByLibrary.simpleMessage("Sigla do observador"),
        "observerSetting":
            MessageLookupByLibrary.simpleMessage("Observador (sigla)"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "optional": MessageLookupByLibrary.simpleMessage("* opcional"),
        "outOfSample": MessageLookupByLibrary.simpleMessage("Fora da amostra"),
        "pause": MessageLookupByLibrary.simpleMessage("Pausa"),
        "permissionDenied":
            MessageLookupByLibrary.simpleMessage("Permissão negada."),
        "permissionDeniedPermanently": MessageLookupByLibrary.simpleMessage(
            "Permissão negada permanentemente."),
        "philornisLarvaePresent": MessageLookupByLibrary.simpleMessage(
            "Presença de larvas de Philornis"),
        "poi": MessageLookupByLibrary.simpleMessage("POI"),
        "pointCounts":
            MessageLookupByLibrary.simpleMessage("Pontos de contagem"),
        "precipitation": MessageLookupByLibrary.simpleMessage("Precipitação *"),
        "precipitationDrizzle": MessageLookupByLibrary.simpleMessage("Garoa"),
        "precipitationFog": MessageLookupByLibrary.simpleMessage("Névoa"),
        "precipitationMist": MessageLookupByLibrary.simpleMessage("Neblina"),
        "precipitationNone": MessageLookupByLibrary.simpleMessage("Nenhuma"),
        "precipitationRain": MessageLookupByLibrary.simpleMessage("Chuva"),
        "proportion": MessageLookupByLibrary.simpleMessage("Proporção"),
        "requiredField": MessageLookupByLibrary.simpleMessage("* obrigatório"),
        "resume": MessageLookupByLibrary.simpleMessage("Retomar"),
        "revision": m19,
        "save": MessageLookupByLibrary.simpleMessage("Salvar"),
        "selectInventoryType": MessageLookupByLibrary.simpleMessage(
            "Por favor, selecione um tipo de inventário"),
        "selectMode": MessageLookupByLibrary.simpleMessage("Selecione o modo"),
        "selectPrecipitation":
            MessageLookupByLibrary.simpleMessage("Selecione uma precipitação"),
        "selectSpecies": MessageLookupByLibrary.simpleMessage(
            "Por favor, selecione uma espécie"),
        "settings": MessageLookupByLibrary.simpleMessage("Configurações"),
        "shareImage":
            MessageLookupByLibrary.simpleMessage("Compartilhar imagem"),
        "shrubs": MessageLookupByLibrary.simpleMessage("Arbustos"),
        "simultaneousInventories":
            MessageLookupByLibrary.simpleMessage("Inventários simultâneos"),
        "simultaneousLimitReached": MessageLookupByLibrary.simpleMessage(
            "Limite de inventários simultâneos atingido."),
        "siteAcronym":
            MessageLookupByLibrary.simpleMessage("Nome ou sigla do local"),
        "species": m20,
        "speciesAcronym": m21,
        "speciesCount": m22,
        "speciesInfo":
            MessageLookupByLibrary.simpleMessage("Informações da espécie"),
        "speciesPerList": m23,
        "speciesPerListTitle":
            MessageLookupByLibrary.simpleMessage("Espécies por lista"),
        "specimenBlood": MessageLookupByLibrary.simpleMessage("Sangue"),
        "specimenBones": MessageLookupByLibrary.simpleMessage("Ossos"),
        "specimenClaw": MessageLookupByLibrary.simpleMessage("Garra"),
        "specimenData": m24,
        "specimenEgg": MessageLookupByLibrary.simpleMessage("Ovo"),
        "specimenExported": m25,
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
        "specimens": m26,
        "startInventory":
            MessageLookupByLibrary.simpleMessage("Iniciar inventário"),
        "startNextList":
            MessageLookupByLibrary.simpleMessage("Iniciar próxima lista"),
        "systemMode": MessageLookupByLibrary.simpleMessage("Tema do sistema"),
        "temperature": MessageLookupByLibrary.simpleMessage("Temperatura"),
        "timeFound":
            MessageLookupByLibrary.simpleMessage("Data e hora de encontro"),
        "timedQualitativeLists": MessageLookupByLibrary.simpleMessage(
            "Listas qualitativas temporizadas"),
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
        "withinSample":
            MessageLookupByLibrary.simpleMessage("Dentro da amostra")
      };
}
