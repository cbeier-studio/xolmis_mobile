// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get inventories => 'Inventários';

  @override
  String get nests => 'Ninhos';

  @override
  String specimens(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Espécimes',
      one: 'Espécime',
    );
    return '$_temp0';
  }

  @override
  String get fieldJournal => 'Diário de campo';

  @override
  String journalEntries(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Notas do diário',
      one: 'Nota do diário',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Configurações';

  @override
  String get general => 'Geral';

  @override
  String get appearance => 'Aparência';

  @override
  String get selectMode => 'Selecione o modo';

  @override
  String get lightMode => 'Claro';

  @override
  String get darkMode => 'Escuro';

  @override
  String get systemMode => 'Tema do sistema';

  @override
  String get observerSetting => 'Observador (sigla)';

  @override
  String get observer => 'Observador';

  @override
  String get observerAbbreviation => 'Sigla do observador';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get simultaneousInventories => 'Inventários simultâneos';

  @override
  String inventory(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'inventários',
      one: 'inventário',
    );
    return '$_temp0';
  }

  @override
  String inventoryFound(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'inventários encontrados',
      one: 'inventário encontrado',
    );
    return '$_temp0';
  }

  @override
  String get mackinnonLists => 'Listas de Mackinnon';

  @override
  String speciesPerList(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: '$howMany espécies',
      one: '1 espécie',
    );
    return '$_temp0 por lista';
  }

  @override
  String get speciesPerListTitle => 'Espécies por lista';

  @override
  String get pointCounts => 'Pontos de contagem';

  @override
  String get durationMin => 'Duração (min)';

  @override
  String inventoryDuration(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: '$howMany minutos',
      one: '1 minuto',
    );
    return '$_temp0 de duração';
  }

  @override
  String get timedQualitativeLists => 'Listas qualitativas temporizadas';

  @override
  String get intervaledQualitativeLists => 'Listas qualitativas por intervalo';

  @override
  String get formatNumbers => 'Formatar números';

  @override
  String get about => 'Sobre o app';

  @override
  String get dangerZone => 'Área perigosa';

  @override
  String get deleteAppData => 'Apagar dados do aplicativo';

  @override
  String get deleteAppDataDescription =>
      'Todos os dados serão apagados. Use com cautela! Esta ação não poderá ser desfeita.';

  @override
  String get deleteData => 'Apagar dados';

  @override
  String get deleteDataMessage =>
      'Tem certeza que deseja apagar todos os dados do aplicativo? Esta ação não poderá ser desfeita.';

  @override
  String get delete => 'Apagar';

  @override
  String get dataDeleted => 'Dados do aplicativo apagados com sucesso!';

  @override
  String get ok => 'OK';

  @override
  String get simultaneousLimitReached =>
      'Limite de inventários simultâneos atingido.';

  @override
  String get sortByTime => 'Ordenar por tempo';

  @override
  String get sortByName => 'Ordenar por nome';

  @override
  String get sortAscending => 'Ordem crescente';

  @override
  String get sortDescending => 'Ordem decrescente';

  @override
  String get findInventories => 'Procurar inventários...';

  @override
  String get active => 'Ativos';

  @override
  String get finished => 'Encerrados';

  @override
  String get noInventoriesFound => 'Nenhum inventário encontrado.';

  @override
  String get deleteInventory => 'Apagar inventário';

  @override
  String get confirmDelete => 'Confirmar exclusão';

  @override
  String confirmDeleteMessage(int howMany, String gender, String what) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'estes',
      'female': 'estas',
      'other': 'estes(as)',
    });
    String _temp1 = intl.Intl.selectLogic(gender, {
      'male': 'este',
      'female': 'esta',
      'other': 'este(a)',
    });
    String _temp2 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: '$_temp0',
      one: '$_temp1',
    );
    return 'Tem certeza que deseja excluir $_temp2 $what?';
  }

  @override
  String get confirmFinish => 'Confirmar encerramento';

  @override
  String get confirmFinishMessage =>
      'Tem certeza que deseja encerrar este inventário?';

  @override
  String get confirmAutoFinishMessage =>
      'Inventário automaticamente encerrado. Você deseja mantê-lo ativo ou finalizar este inventário?';

  @override
  String get finish => 'Encerrar';

  @override
  String get keepRunning => 'Manter ativo';

  @override
  String get newInventory => 'Novo inventário';

  @override
  String speciesCount(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'espécies',
      one: 'espécie',
      zero: 'espécies',
    );
    return '$_temp0';
  }

  @override
  String get pause => 'Pausa';

  @override
  String get resume => 'Retomar';

  @override
  String get export => 'Exportar';

  @override
  String exportWhat(String what) {
    return 'Exportar $what';
  }

  @override
  String get exportAll => 'Exportar todos';

  @override
  String exportAllWhat(String what) {
    return 'Exportar todos os $what';
  }

  @override
  String get finishInventory => 'Encerrar inventário';

  @override
  String get requiredField => '* obrigatório';

  @override
  String get inventoryType => 'Tipo de inventário';

  @override
  String get selectInventoryType =>
      'Por favor, selecione um tipo de inventário';

  @override
  String get inventoryId => 'ID do Inventário';

  @override
  String get generateId => 'Gerar ID';

  @override
  String get siteAbbreviation => 'Nome ou sigla do local';

  @override
  String get optional => '* opcional';

  @override
  String get insertInventoryId => 'Por favor, insira uma ID para o inventário';

  @override
  String get duration => 'Duração';

  @override
  String minutes(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'minutos',
      one: 'minuto',
    );
    return '$_temp0';
  }

  @override
  String get insertDuration => 'Insira uma duração';

  @override
  String get maxSpecies => 'Máx. espécies';

  @override
  String get insertMaxSpecies => 'Insira o máximo de espécies';

  @override
  String get mustBeBiggerThanFive => 'Deve ser maior ou igual a 5';

  @override
  String get startInventory => 'Iniciar inventário';

  @override
  String get inventoryIdAlreadyExists => 'Já existe um inventário com esta ID.';

  @override
  String get errorInsertingInventory => 'Erro ao inserir inventário.';

  @override
  String get reportSpeciesByInventory => 'Espécies por inventário';

  @override
  String get totalSpecies => 'Total de espécies';

  @override
  String get totalIndividuals => 'Total de indivíduos';

  @override
  String get speciesAccumulationCurve => 'Curva de acumulação de espécies';

  @override
  String get speciesAccumulated => 'Acumulado de espécies';

  @override
  String get timeMinutes => 'Tempo (intervalos de 10 minutos)';

  @override
  String get speciesCounted => 'Número de espécies';

  @override
  String get individualsCounted => 'Número de indivíduos';

  @override
  String get close => 'Fechar';

  @override
  String get refreshList => 'Atualizar';

  @override
  String get noDataAvailable => 'Dados não disponíveis.';

  @override
  String get clearSelection => 'Limpar seleção';

  @override
  String get importingInventory => 'Importando inventário...';

  @override
  String get inventoryImportedSuccessfully =>
      'Inventário importado com sucesso!';

  @override
  String get inventoryImportFailed => 'Falha ao importar inventário.';

  @override
  String get noFileSelected => 'Nenhum arquivo selecionado.';

  @override
  String get import => 'Importar';

  @override
  String get errorImportingInventory => 'Erro ao importar inventário.';

  @override
  String get vegetationData => 'Dados de vegetação';

  @override
  String get herbs => 'Herbáceas';

  @override
  String get distribution => 'Distribuição';

  @override
  String get proportion => 'Proporção';

  @override
  String get height => 'Altura';

  @override
  String get shrubs => 'Arbustos';

  @override
  String get trees => 'Árvores';

  @override
  String get notes => 'Observações';

  @override
  String get insertProportion => 'Insira a proporção';

  @override
  String get insertHeight => 'Insira a altura';

  @override
  String get errorSavingVegetation => 'Erro ao salvar os dados de vegetação';

  @override
  String get weatherData => 'Dados do tempo';

  @override
  String get cloudCover => 'Nebulosidade';

  @override
  String get precipitation => 'Precipitação';

  @override
  String get selectPrecipitation => 'Selecione uma precipitação';

  @override
  String get temperature => 'Temperatura';

  @override
  String get windSpeed => 'Vento';

  @override
  String get windSpeedRangeError => 'Deve estar entre 0 e 12 bft';

  @override
  String get errorSavingWeather => 'Erro ao salvar os dados do tempo';

  @override
  String species(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Espécies',
      one: 'Espécie',
    );
    return '$_temp0';
  }

  @override
  String speciesAcronym(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'spp.',
      one: 'sp.',
    );
    return '$_temp0';
  }

  @override
  String get vegetation => 'Vegetação';

  @override
  String get weather => 'Tempo';

  @override
  String get errorGettingLocation => 'Erro ao obter a localização.';

  @override
  String get poi => 'POI';

  @override
  String get speciesInfo => 'Informações da espécie';

  @override
  String get count => 'Contagem';

  @override
  String get recordTime => 'Hora do registro';

  @override
  String individual(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'indivíduos',
      one: 'indivíduo',
    );
    return '$_temp0';
  }

  @override
  String get outOfSample => 'Fora da amostra';

  @override
  String get withinSample => 'Dentro da amostra';

  @override
  String get noPoiFound => 'Nenhum POI encontrado.';

  @override
  String get newPoi => 'Novo POI';

  @override
  String get deletePoi => 'Apagar POI';

  @override
  String get decreaseIndividuals => 'Diminuir contagem de indivíduos';

  @override
  String get increaseIndividuals => 'Aumentar contagem de indivíduos';

  @override
  String get addPoi => 'Adicionar POI';

  @override
  String get editCount => 'Editar contagem';

  @override
  String get individualsCount => 'Contagem de indivíduos';

  @override
  String get deleteVegetation => 'Apagar registro de vegetação';

  @override
  String get noVegetationFound => 'Nenhum registro de vegetação';

  @override
  String get weatherRecord => 'registro do tempo';

  @override
  String get noWeatherFound => 'Nenhum registro do tempo';

  @override
  String get deleteWeather => 'Apagar registro do tempo';

  @override
  String get findNests => 'Procurar ninhos...';

  @override
  String get inactive => 'Inativos';

  @override
  String get noNestsFound => 'Nenhum ninho encontrado.';

  @override
  String nest(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'ninhos',
      one: 'ninho',
    );
    return '$_temp0';
  }

  @override
  String get newNest => 'Novo ninho';

  @override
  String get deleteNest => 'Apagar ninho';

  @override
  String get confirmFate => 'Confirmar destino';

  @override
  String get nestFate => 'Destino do ninho';

  @override
  String errorInactivatingNest(String errorMessage) {
    return 'Erro ao desativar o ninho: $errorMessage';
  }

  @override
  String revision(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Revisões',
      one: 'Revisão',
    );
    return '$_temp0';
  }

  @override
  String egg(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Ovos',
      one: 'Ovo',
    );
    return '$_temp0';
  }

  @override
  String get nestInfo => 'Informações do ninho';

  @override
  String get timeFound => 'Data e hora de encontro';

  @override
  String get locality => 'Localidade';

  @override
  String get nestSupport => 'Suporte do ninho';

  @override
  String get heightAboveGround => 'Altura acima do solo';

  @override
  String get male => 'Macho';

  @override
  String get female => 'Fêmea';

  @override
  String get helpers => 'Ajudantes de ninho';

  @override
  String get noEggsFound => 'Nenhum ovo registrado.';

  @override
  String get deleteEgg => 'Apagar ovo';

  @override
  String get noRevisionsFound => 'Nenhuma revisão registrada.';

  @override
  String get deleteRevision => 'Apagar revisão de ninho';

  @override
  String get host => 'Hospedeiro';

  @override
  String get nidoparasite => 'Nidoparasita';

  @override
  String nestling(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Ninhegos',
      one: 'Ninhego',
    );
    return '$_temp0';
  }

  @override
  String get addEgg => 'Adicionar ovo';

  @override
  String get fieldNumber => 'Número de campo';

  @override
  String get insertFieldNumber => 'Insira o número de campo';

  @override
  String get selectSpecies => 'Selecione uma espécie';

  @override
  String get eggShape => 'Forma do ovo';

  @override
  String get width => 'Largura';

  @override
  String get length => 'Comprimento';

  @override
  String get weight => 'Peso';

  @override
  String get errorEggAlreadyExists =>
      'Já existe um ovo com este número de campo.';

  @override
  String get errorSavingEgg => 'Erro ao salvar o ovo.';

  @override
  String get insertLocality => 'Por favor, insira o nome da localidade';

  @override
  String get insertNestSupport => 'Por favor, insira o suporte do ninho';

  @override
  String get errorNestAlreadyExists =>
      'Já existe um ninho com este número de campo.';

  @override
  String get errorSavingNest => 'Erro ao salvar o ninho.';

  @override
  String get nestRevision => 'Revisão de ninho';

  @override
  String get nestStatus => 'Status do ninho';

  @override
  String get nestPhase => 'Estágio';

  @override
  String get philornisLarvaePresent => 'Presença de larvas de Philornis';

  @override
  String get errorSavingRevision => 'Erro ao salvar a revisão de ninho.';

  @override
  String get findSpecimens => 'Procurar espécimes...';

  @override
  String get noSpecimenCollected => 'Nenhum espécime coletado.';

  @override
  String get newSpecimen => 'Novo espécime';

  @override
  String get deleteSpecimen => 'Apagar espécime';

  @override
  String get specimenType => 'Tipo de espécime';

  @override
  String get errorSpecimenAlreadyExists =>
      'Já existe um espécime com este número de campo.';

  @override
  String get errorSavingSpecimen => 'Erro ao salvar o espécime.';

  @override
  String images(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Imagens',
      one: 'Imagem',
    );
    return '$_temp0';
  }

  @override
  String get noImagesFound => 'Nenhuma imagem encontrada.';

  @override
  String get addImage => 'Adicionar imagem';

  @override
  String get gallery => 'Galeria';

  @override
  String get camera => 'Câmera';

  @override
  String get permissionDenied => 'Permissão negada.';

  @override
  String get permissionDeniedPermanently => 'Permissão negada permanentemente.';

  @override
  String get shareImage => 'Compartilhar imagem';

  @override
  String get editImageNotes => 'Editar notas da imagem';

  @override
  String get deleteImage => 'Apagar imagem';

  @override
  String get editNotes => 'Editar notas';

  @override
  String get imageDetails => 'Detalhes da imagem';

  @override
  String inventoryExported(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Inventários exportados!',
      one: 'Inventário exportado!',
    );
    return '$_temp0';
  }

  @override
  String inventoryData(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Dados dos inventários',
      one: 'Dados do inventário',
    );
    return '$_temp0';
  }

  @override
  String errorExportingInventory(int howMany, String errorMessage) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'os inventários',
      one: 'o inventário',
    );
    return 'Erro ao exportar $_temp0: $errorMessage';
  }

  @override
  String nestExported(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Ninhos exportados!',
      one: 'Ninho exportado!',
    );
    return '$_temp0';
  }

  @override
  String nestData(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Dados dos ninhos',
      one: 'Dados do ninho',
    );
    return '$_temp0';
  }

  @override
  String errorExportingNest(int howMany, String errorMessage) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'os ninhos',
      one: 'o ninho',
    );
    return 'Erro ao exportar $_temp0: $errorMessage';
  }

  @override
  String specimenExported(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Espécimes exportados!',
      one: 'Espécime exportado!',
    );
    return '$_temp0';
  }

  @override
  String specimenData(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Dados dos espécimes',
      one: 'Dados do espécime',
    );
    return '$_temp0';
  }

  @override
  String errorExportingSpecimen(int howMany, String errorMessage) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'os espécimes',
      one: 'o espécime',
    );
    return 'Erro ao exportar $_temp0: $errorMessage';
  }

  @override
  String get findSpecies => 'Buscar espécie';

  @override
  String get addSpecies => 'Adicionar espécie';

  @override
  String get deleteSpecies => 'Apagar espécie';

  @override
  String get speciesNotes => 'Anotações da espécie';

  @override
  String get noSpeciesFound => 'Nenhuma espécie registrada';

  @override
  String get speciesName => 'Nome da espécie';

  @override
  String get errorSpeciesAlreadyExists => 'Espécie já adicionada à lista';

  @override
  String get addSpeciesToSample => 'Incluir na amostra';

  @override
  String get removeSpeciesFromSample => 'Remover da amostra';

  @override
  String get reactivateInventory => 'Reativar inventário';

  @override
  String get listFinished => 'Lista concluída';

  @override
  String get listFinishedMessage =>
      'A lista atingiu o número máximo de espécies. Deseja iniciar a próxima lista ou encerrar?';

  @override
  String get startNextList => 'Iniciar próxima lista';

  @override
  String get editSpecimen => 'Editar espécime';

  @override
  String get editNest => 'Editar ninho';

  @override
  String get editNestRevision => 'Editar revisão de ninho';

  @override
  String get editEgg => 'Editar ovo';

  @override
  String get editWeather => 'Editar dados do tempo';

  @override
  String get editVegetation => 'Editar dados de vegetação';

  @override
  String get editInventoryId => 'Editar ID';

  @override
  String get confirmDeleteSpecies => 'Remover espécie';

  @override
  String confirmDeleteSpeciesMessage(String speciesName) {
    return 'Deseja remover a espécie $speciesName dos outros inventários ativos?';
  }

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get newJournalEntry => 'Nova nota';

  @override
  String get sortByLastModified => 'Ordenar por última modificação';

  @override
  String get sortByTitle => 'Ordenar por título';

  @override
  String get findJournalEntries => 'Procurar notas';

  @override
  String get noJournalEntriesFound => 'Nenhuma nota encontrada';

  @override
  String get title => 'Título';

  @override
  String get insertTitle => 'Insira um título para a nota';

  @override
  String get errorSavingJournalEntry =>
      'Erro ao salvar a nota do diário de campo';

  @override
  String get deleteJournalEntry => 'Apagar nota';

  @override
  String get editJournalEntry => 'Editar nota';

  @override
  String get statistics => 'Estatísticas';

  @override
  String get selectSpeciesToShowStats =>
      'Selecione uma espécie para ver as estatísticas';

  @override
  String get perSpecies => 'Por espécie';

  @override
  String get totalRecords => 'Total de registros';

  @override
  String get recordsPerMonth => 'Registros por mês';

  @override
  String get recordsPerYear => 'Registros por ano';

  @override
  String get addCoordinates => 'Adicionar coordenadas';

  @override
  String get recordedSpecies => 'espécies registradas';

  @override
  String get topTenSpecies => 'Top 10 espécies mais registradas';

  @override
  String get surveyHours => 'horas de amostragem';

  @override
  String get averageSurveyHours => 'horas de amostragem por inventário';

  @override
  String get pending => 'Pendentes';

  @override
  String get archived => 'Arquivados';

  @override
  String get archiveSpecimen => 'Arquivar espécime';

  @override
  String get maleNameOrId => 'Nome ou ID do macho';

  @override
  String get femaleNameOrId => 'Nome ou ID da fêmea';

  @override
  String get helpersNamesOrIds => 'Nomes ou IDs dos ajudantes';

  @override
  String get plantSpeciesOrSupportType => 'Espécie vegetal ou tipo de suporte';

  @override
  String get formatNumbersDescription =>
      'Desmarque para formatar números com ponto como separador decimal';

  @override
  String get selectAll => 'Selecionar todos';

  @override
  String get exporting => 'Exportando...';

  @override
  String get noDataToExport => 'Sem dados para exportar.';

  @override
  String get exportingPleaseWait => 'Exportando, aguarde...';

  @override
  String get errorTitle => 'Erro';

  @override
  String get warningTitle => 'Aviso';

  @override
  String get remindMissingVegetationData =>
      'Lembrar dados faltantes de vegetação';

  @override
  String get remindMissingWeatherData => 'Lembrar dados faltantes do tempo';

  @override
  String get missingVegetationData => 'Não há dados de vegetação.';

  @override
  String get missingWeatherData => 'Não há dados do tempo.';

  @override
  String get addButton => 'Adicionar';

  @override
  String get ignoreButton => 'Ignorar';

  @override
  String get observerAbbreviationMissing =>
      'Sigla do observador não encontrada. Adicione-a nas configurações.';

  @override
  String get invalidNumericValue => 'Valor inválido';

  @override
  String get nestRevisionsMissing =>
      'Não há revisões para este ninho. Adicione ao menos uma revisão.';

  @override
  String get editLocality => 'Editar localidade';

  @override
  String get addEditNotes => 'Adicionar/editar anotações';

  @override
  String get exportKml => 'Exportar KML';

  @override
  String get edit => 'Editar';

  @override
  String get noPoisToExport => 'Nenhum POI para exportar.';

  @override
  String get totalSpeciesWithinSample => 'Espécies na amostra';

  @override
  String get details => 'Detalhes';

  @override
  String get editInventoryDetails => 'Detalhes do inventário';

  @override
  String get discardedInventory => 'Inventário descartado';

  @override
  String errorImportingInventoryWithFormatError(String errorMessage) {
    return 'Erro de formato ao importar inventário: $errorMessage';
  }

  @override
  String inventoriesImportedSuccessfully(int howMany) {
    return 'Inventários importados com sucesso: $howMany';
  }

  @override
  String importCompletedWithErrors(
    int successfullyImportedCount,
    int importErrorsCount,
  ) {
    return 'Importação concluída com erros: $successfullyImportedCount com sucesso, $importErrorsCount erros';
  }

  @override
  String failedToImportInventoryWithId(String id) {
    return 'Falha ao importar inventário com ID: $id';
  }

  @override
  String get invalidJsonFormatExpectedObjectOrArray =>
      'Formato JSON inválido. Esperado um objeto ou uma lista.';

  @override
  String get importingNests => 'Importando ninhos';

  @override
  String get errorImportingNests => 'Erro importando ninhos';

  @override
  String errorImportingNestsWithFormatError(String errorMessage) {
    return 'Erro de formato importando ninho: $errorMessage';
  }

  @override
  String nestsImportedSuccessfully(int howMany) {
    return 'Ninhos importados com sucesso: $howMany';
  }

  @override
  String failedToImportNestWithId(int id) {
    return 'Falha ao importar ninho com ID: $id';
  }

  @override
  String get backup => 'Backup';

  @override
  String get createBackup => 'Criar backup';

  @override
  String get sendBackupTo => 'Enviar backup para...';

  @override
  String get backupCreatedAndSharedSuccessfully =>
      'Backup criado e compartilhado com sucesso';

  @override
  String get errorCreatingBackup => 'Erro criando backup';

  @override
  String get errorBackupNotFound => 'Backup não encontrado';

  @override
  String get restoreBackup => 'Restaurar backup';

  @override
  String get backupRestoredSuccessfully =>
      'Backup restaurado com sucesso! Reinicie o app para aplicar as alterações.';

  @override
  String get errorRestoringBackup => 'Erro restaurando backup';

  @override
  String get backingUpData => 'Criando backup dos dados';

  @override
  String get restoringData => 'Restaurando dados';

  @override
  String get importingSpecimens => 'Importando espécimes';

  @override
  String get errorImportingSpecimens => 'Erro importando espécimes';

  @override
  String errorImportingSpecimensWithFormatError(String errorMessage) {
    return 'Erro de formato importando espécime: $errorMessage';
  }

  @override
  String specimensImportedSuccessfully(int howMany) {
    return 'Espécimes importados com sucesso: $howMany';
  }

  @override
  String failedToImportSpecimenWithId(int id) {
    return 'Falha ao importar espécime com ID: $id';
  }

  @override
  String get cloudCoverRangeError => 'Nebulosidade deve estar entre 0 e 100';

  @override
  String get relativeHumidityRangeError =>
      'Umidade relativa deve estar entre 0 e 100';

  @override
  String get atmosphericPressure => 'Pressão atmosférica';

  @override
  String get relativeHumidity => 'Umidade relativa';

  @override
  String get totalOfObservers => 'Total de observadores';

  @override
  String get enterCoordinates => 'Entrar coordenadas';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get invalidLatitude => 'Latitude inválida';

  @override
  String get invalidLongitude => 'Longitude inválida';

  @override
  String get fieldCannotBeEmpty => 'Campo deve ser preenchido';

  @override
  String get locationError => 'Erro de localização';

  @override
  String get couldNotGetGpsLocation =>
      'Não foi possível obter a localização do GPS';

  @override
  String get continueWithout => 'Continuar sem';

  @override
  String get enterManually => 'Entrar manualmente';

  @override
  String get distance => 'Distância';

  @override
  String get flightHeight => 'Altura de voo';

  @override
  String get flightDirection => 'Direção de voo';

  @override
  String get insertCount => 'Insira a contagem';

  @override
  String get insertValidNumber => 'Insira um número válido';

  @override
  String get windDirection => 'Direção do vento';

  @override
  String get reactivate => 'Reativar';

  @override
  String get archive => 'Arquivar';

  @override
  String get platinumSponsor => 'Patrocinador Platina';

  @override
  String get changelog => 'Log de alterações';

  @override
  String get viewLicense => 'Ver licença';

  @override
  String get openSourceLicenses => 'Licenças de código aberto';

  @override
  String get precipitationNone => 'Nenhuma';

  @override
  String get precipitationFog => 'Névoa';

  @override
  String get precipitationMist => 'Neblina';

  @override
  String get precipitationDrizzle => 'Garoa';

  @override
  String get precipitationRain => 'Chuva';

  @override
  String get precipitationShowers => 'Pancadas';

  @override
  String get precipitationSnow => 'Neve';

  @override
  String get precipitationHail => 'Granizo';

  @override
  String get precipitationFrost => 'Geada';

  @override
  String get distributionNone => 'Nada';

  @override
  String get distributionRare => 'Rara';

  @override
  String get distributionFewSparseIndividuals => 'Poucos indivíduos esparsos';

  @override
  String get distributionOnePatch => 'Uma mancha';

  @override
  String get distributionOnePatchFewSparseIndividuals =>
      'Uma mancha e indivíduos isolados';

  @override
  String get distributionManySparseIndividuals => 'Vários indivíduos esparsos';

  @override
  String get distributionOnePatchManySparseIndividuals =>
      'Mancha e vários indivíduos isolados';

  @override
  String get distributionFewPatches => 'Poucas manchas';

  @override
  String get distributionFewPatchesSparseIndividuals =>
      'Poucas manchas e indivíduos isolados';

  @override
  String get distributionManyPatches => 'Várias manchas equidistantes';

  @override
  String get distributionManyPatchesSparseIndividuals =>
      'Várias manchas e indivíduos dispersos';

  @override
  String get distributionHighDensityIndividuals =>
      'Indivíduos isolados em alta densidade';

  @override
  String get distributionContinuousCoverWithGaps =>
      'Contínua com manchas sem cobertura';

  @override
  String get distributionContinuousDenseCover => 'Contínua e densa';

  @override
  String get distributionContinuousDenseCoverWithEdge =>
      'Contínua com borda separando estratos';

  @override
  String get inventoryFreeQualitative => 'Lista Qualitativa Livre';

  @override
  String get inventoryTimedQualitative => 'Lista Qualitativa Temporizada';

  @override
  String get inventoryIntervalQualitative => 'Lista Qualitativa por Intervalos';

  @override
  String get inventoryMackinnonList => 'Lista de Mackinnon';

  @override
  String get inventoryTransectCount => 'Contagem em Transecto';

  @override
  String get inventoryPointCount => 'Ponto de Contagem';

  @override
  String get inventoryBanding => 'Anilhamento';

  @override
  String get inventoryCasual => 'Observação Casual';

  @override
  String get inventoryTransectDetection => 'Transecto de Detecções';

  @override
  String get inventoryPointDetection => 'Ponto de Detecções';

  @override
  String get eggShapeSpherical => 'Esférico';

  @override
  String get eggShapeElliptical => 'Elíptico';

  @override
  String get eggShapeOval => 'Oval';

  @override
  String get eggShapePyriform => 'Piriforme';

  @override
  String get eggShapeConical => 'Cônico';

  @override
  String get eggShapeBiconical => 'Bicônico';

  @override
  String get eggShapeCylindrical => 'Cilíndrico';

  @override
  String get eggShapeLongitudinal => 'Longitudinal';

  @override
  String get nestStageUnknown => 'Indeterminado';

  @override
  String get nestStageBuilding => 'Construção';

  @override
  String get nestStageLaying => 'Postura';

  @override
  String get nestStageIncubating => 'Incubação';

  @override
  String get nestStageHatching => 'Eclosão';

  @override
  String get nestStageNestling => 'Ninhego';

  @override
  String get nestStageInactive => 'Inativo';

  @override
  String get nestStatusUnknown => 'Indeterminado';

  @override
  String get nestStatusActive => 'Ativo';

  @override
  String get nestStatusInactive => 'Inativo';

  @override
  String get nestFateUnknown => 'Indeterminado';

  @override
  String get nestFateLost => 'Perdido';

  @override
  String get nestFateSuccess => 'Sucesso';

  @override
  String get specimenWholeCarcass => 'Carcaça inteira';

  @override
  String get specimenPartialCarcass => 'Carcaça parcial';

  @override
  String get specimenNest => 'Ninho';

  @override
  String get specimenBones => 'Ossos';

  @override
  String get specimenEgg => 'Ovo';

  @override
  String get specimenParasites => 'Parasitas';

  @override
  String get specimenFeathers => 'Penas';

  @override
  String get specimenBlood => 'Sangue';

  @override
  String get specimenClaw => 'Garra';

  @override
  String get specimenSwab => 'Swab';

  @override
  String get specimenTissues => 'Tecidos';

  @override
  String get specimenFeces => 'Fezes';

  @override
  String get specimenRegurgite => 'Regurgito';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get inventories => 'Inventários';

  @override
  String get nests => 'Ninhos';

  @override
  String specimens(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Espécimes',
      one: 'Espécime',
    );
    return '$_temp0';
  }

  @override
  String get fieldJournal => 'Diário de campo';

  @override
  String journalEntries(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Notas do diário',
      one: 'Nota do diário',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Configurações';

  @override
  String get general => 'Geral';

  @override
  String get appearance => 'Aparência';

  @override
  String get selectMode => 'Selecione o modo';

  @override
  String get lightMode => 'Claro';

  @override
  String get darkMode => 'Escuro';

  @override
  String get systemMode => 'Tema do sistema';

  @override
  String get observerSetting => 'Observador (sigla)';

  @override
  String get observer => 'Observador';

  @override
  String get observerAbbreviation => 'Sigla do observador';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get simultaneousInventories => 'Inventários simultâneos';

  @override
  String inventory(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'inventários',
      one: 'inventário',
    );
    return '$_temp0';
  }

  @override
  String inventoryFound(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'inventários encontrados',
      one: 'inventário encontrado',
    );
    return '$_temp0';
  }

  @override
  String get mackinnonLists => 'Listas de Mackinnon';

  @override
  String speciesPerList(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: '$howMany espécies',
      one: '1 espécie',
    );
    return '$_temp0 por lista';
  }

  @override
  String get speciesPerListTitle => 'Espécies por lista';

  @override
  String get pointCounts => 'Pontos de contagem';

  @override
  String get durationMin => 'Duração (min)';

  @override
  String inventoryDuration(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: '$howMany minutos',
      one: '1 minuto',
    );
    return '$_temp0 de duração';
  }

  @override
  String get timedQualitativeLists => 'Listas qualitativas temporizadas';

  @override
  String get intervaledQualitativeLists => 'Listas qualitativas por intervalo';

  @override
  String get formatNumbers => 'Formatar números';

  @override
  String get about => 'Sobre o app';

  @override
  String get dangerZone => 'Área perigosa';

  @override
  String get deleteAppData => 'Apagar dados do aplicativo';

  @override
  String get deleteAppDataDescription =>
      'Todos os dados serão apagados. Use com cautela! Esta ação não poderá ser desfeita.';

  @override
  String get deleteData => 'Apagar dados';

  @override
  String get deleteDataMessage =>
      'Tem certeza que deseja apagar todos os dados do aplicativo? Esta ação não poderá ser desfeita.';

  @override
  String get delete => 'Apagar';

  @override
  String get dataDeleted => 'Dados do aplicativo apagados com sucesso!';

  @override
  String get ok => 'OK';

  @override
  String get simultaneousLimitReached =>
      'Limite de inventários simultâneos atingido.';

  @override
  String get sortByTime => 'Ordenar por tempo';

  @override
  String get sortByName => 'Ordenar por nome';

  @override
  String get sortAscending => 'Ordem crescente';

  @override
  String get sortDescending => 'Ordem decrescente';

  @override
  String get findInventories => 'Procurar inventários...';

  @override
  String get active => 'Ativos';

  @override
  String get finished => 'Encerrados';

  @override
  String get noInventoriesFound => 'Nenhum inventário encontrado.';

  @override
  String get deleteInventory => 'Apagar inventário';

  @override
  String get confirmDelete => 'Confirmar exclusão';

  @override
  String confirmDeleteMessage(int howMany, String gender, String what) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'estes',
      'female': 'estas',
      'other': 'estes(as)',
    });
    String _temp1 = intl.Intl.selectLogic(gender, {
      'male': 'este',
      'female': 'esta',
      'other': 'este(a)',
    });
    String _temp2 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: '$_temp0',
      one: '$_temp1',
    );
    return 'Tem certeza que deseja excluir $_temp2 $what?';
  }

  @override
  String get confirmFinish => 'Confirmar encerramento';

  @override
  String get confirmFinishMessage =>
      'Tem certeza que deseja encerrar este inventário?';

  @override
  String get confirmAutoFinishMessage =>
      'Inventário automaticamente encerrado. Você deseja mantê-lo ativo ou finalizar este inventário?';

  @override
  String get finish => 'Encerrar';

  @override
  String get keepRunning => 'Manter ativo';

  @override
  String get newInventory => 'Novo inventário';

  @override
  String speciesCount(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'espécies',
      one: 'espécie',
      zero: 'espécies',
    );
    return '$_temp0';
  }

  @override
  String get pause => 'Pausa';

  @override
  String get resume => 'Retomar';

  @override
  String get export => 'Exportar';

  @override
  String exportWhat(String what) {
    return 'Exportar $what';
  }

  @override
  String get exportAll => 'Exportar todos';

  @override
  String exportAllWhat(String what) {
    return 'Exportar todos os $what';
  }

  @override
  String get finishInventory => 'Encerrar inventário';

  @override
  String get requiredField => '* obrigatório';

  @override
  String get inventoryType => 'Tipo de inventário';

  @override
  String get selectInventoryType =>
      'Por favor, selecione um tipo de inventário';

  @override
  String get inventoryId => 'ID do Inventário';

  @override
  String get generateId => 'Gerar ID';

  @override
  String get siteAbbreviation => 'Nome ou sigla do local';

  @override
  String get optional => '* opcional';

  @override
  String get insertInventoryId => 'Por favor, insira uma ID para o inventário';

  @override
  String get duration => 'Duração';

  @override
  String minutes(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'minutos',
      one: 'minuto',
    );
    return '$_temp0';
  }

  @override
  String get insertDuration => 'Insira uma duração';

  @override
  String get maxSpecies => 'Máx. espécies';

  @override
  String get insertMaxSpecies => 'Insira o máximo de espécies';

  @override
  String get mustBeBiggerThanFive => 'Deve ser maior ou igual a 5';

  @override
  String get startInventory => 'Iniciar inventário';

  @override
  String get inventoryIdAlreadyExists => 'Já existe um inventário com esta ID.';

  @override
  String get errorInsertingInventory => 'Erro ao inserir inventário.';

  @override
  String get reportSpeciesByInventory => 'Espécies por inventário';

  @override
  String get totalSpecies => 'Total de espécies';

  @override
  String get totalIndividuals => 'Total de indivíduos';

  @override
  String get speciesAccumulationCurve => 'Curva de acumulação de espécies';

  @override
  String get speciesAccumulated => 'Acumulado de espécies';

  @override
  String get timeMinutes => 'Tempo (intervalos de 10 minutos)';

  @override
  String get speciesCounted => 'Número de espécies';

  @override
  String get individualsCounted => 'Número de indivíduos';

  @override
  String get close => 'Fechar';

  @override
  String get refreshList => 'Atualizar';

  @override
  String get noDataAvailable => 'Dados não disponíveis.';

  @override
  String get clearSelection => 'Limpar seleção';

  @override
  String get importingInventory => 'Importando inventário...';

  @override
  String get inventoryImportedSuccessfully =>
      'Inventário importado com sucesso!';

  @override
  String get inventoryImportFailed => 'Falha ao importar inventário.';

  @override
  String get noFileSelected => 'Nenhum arquivo selecionado.';

  @override
  String get import => 'Importar';

  @override
  String get errorImportingInventory => 'Erro ao importar inventário.';

  @override
  String get vegetationData => 'Dados de vegetação';

  @override
  String get herbs => 'Herbáceas';

  @override
  String get distribution => 'Distribuição';

  @override
  String get proportion => 'Proporção';

  @override
  String get height => 'Altura';

  @override
  String get shrubs => 'Arbustos';

  @override
  String get trees => 'Árvores';

  @override
  String get notes => 'Observações';

  @override
  String get insertProportion => 'Insira a proporção';

  @override
  String get insertHeight => 'Insira a altura';

  @override
  String get errorSavingVegetation => 'Erro ao salvar os dados de vegetação';

  @override
  String get weatherData => 'Dados do tempo';

  @override
  String get cloudCover => 'Nebulosidade';

  @override
  String get precipitation => 'Precipitação';

  @override
  String get selectPrecipitation => 'Selecione uma precipitação';

  @override
  String get temperature => 'Temperatura';

  @override
  String get windSpeed => 'Vento';

  @override
  String get windSpeedRangeError => 'Deve estar entre 0 e 12 bft';

  @override
  String get errorSavingWeather => 'Erro ao salvar os dados do tempo';

  @override
  String species(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Espécies',
      one: 'Espécie',
    );
    return '$_temp0';
  }

  @override
  String speciesAcronym(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'spp.',
      one: 'sp.',
    );
    return '$_temp0';
  }

  @override
  String get vegetation => 'Vegetação';

  @override
  String get weather => 'Tempo';

  @override
  String get errorGettingLocation => 'Erro ao obter a localização.';

  @override
  String get poi => 'POI';

  @override
  String get speciesInfo => 'Informações da espécie';

  @override
  String get count => 'Contagem';

  @override
  String get recordTime => 'Hora do registro';

  @override
  String individual(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'indivíduos',
      one: 'indivíduo',
    );
    return '$_temp0';
  }

  @override
  String get outOfSample => 'Fora da amostra';

  @override
  String get withinSample => 'Dentro da amostra';

  @override
  String get noPoiFound => 'Nenhum POI encontrado.';

  @override
  String get newPoi => 'Novo POI';

  @override
  String get deletePoi => 'Apagar POI';

  @override
  String get decreaseIndividuals => 'Diminuir contagem de indivíduos';

  @override
  String get increaseIndividuals => 'Aumentar contagem de indivíduos';

  @override
  String get addPoi => 'Adicionar POI';

  @override
  String get editCount => 'Editar contagem';

  @override
  String get individualsCount => 'Contagem de indivíduos';

  @override
  String get deleteVegetation => 'Apagar registro de vegetação';

  @override
  String get noVegetationFound => 'Nenhum registro de vegetação';

  @override
  String get weatherRecord => 'registro do tempo';

  @override
  String get noWeatherFound => 'Nenhum registro do tempo';

  @override
  String get deleteWeather => 'Apagar registro do tempo';

  @override
  String get findNests => 'Procurar ninhos...';

  @override
  String get inactive => 'Inativos';

  @override
  String get noNestsFound => 'Nenhum ninho encontrado.';

  @override
  String nest(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'ninhos',
      one: 'ninho',
    );
    return '$_temp0';
  }

  @override
  String get newNest => 'Novo ninho';

  @override
  String get deleteNest => 'Apagar ninho';

  @override
  String get confirmFate => 'Confirmar destino';

  @override
  String get nestFate => 'Destino do ninho';

  @override
  String errorInactivatingNest(String errorMessage) {
    return 'Erro ao desativar o ninho: $errorMessage';
  }

  @override
  String revision(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Revisões',
      one: 'Revisão',
    );
    return '$_temp0';
  }

  @override
  String egg(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Ovos',
      one: 'Ovo',
    );
    return '$_temp0';
  }

  @override
  String get nestInfo => 'Informações do ninho';

  @override
  String get timeFound => 'Data e hora de encontro';

  @override
  String get locality => 'Localidade';

  @override
  String get nestSupport => 'Suporte do ninho';

  @override
  String get heightAboveGround => 'Altura acima do solo';

  @override
  String get male => 'Macho';

  @override
  String get female => 'Fêmea';

  @override
  String get helpers => 'Ajudantes de ninho';

  @override
  String get noEggsFound => 'Nenhum ovo registrado.';

  @override
  String get deleteEgg => 'Apagar ovo';

  @override
  String get noRevisionsFound => 'Nenhuma revisão registrada.';

  @override
  String get deleteRevision => 'Apagar revisão de ninho';

  @override
  String get host => 'Hospedeiro';

  @override
  String get nidoparasite => 'Nidoparasita';

  @override
  String nestling(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Ninhegos',
      one: 'Ninhego',
    );
    return '$_temp0';
  }

  @override
  String get addEgg => 'Adicionar ovo';

  @override
  String get fieldNumber => 'Número de campo';

  @override
  String get insertFieldNumber => 'Insira o número de campo';

  @override
  String get selectSpecies => 'Selecione uma espécie';

  @override
  String get eggShape => 'Forma do ovo';

  @override
  String get width => 'Largura';

  @override
  String get length => 'Comprimento';

  @override
  String get weight => 'Peso';

  @override
  String get errorEggAlreadyExists =>
      'Já existe um ovo com este número de campo.';

  @override
  String get errorSavingEgg => 'Erro ao salvar o ovo.';

  @override
  String get insertLocality => 'Por favor, insira o nome da localidade';

  @override
  String get insertNestSupport => 'Por favor, insira o suporte do ninho';

  @override
  String get errorNestAlreadyExists =>
      'Já existe um ninho com este número de campo.';

  @override
  String get errorSavingNest => 'Erro ao salvar o ninho.';

  @override
  String get nestRevision => 'Revisão de ninho';

  @override
  String get nestStatus => 'Status do ninho';

  @override
  String get nestPhase => 'Estágio';

  @override
  String get philornisLarvaePresent => 'Presença de larvas de Philornis';

  @override
  String get errorSavingRevision => 'Erro ao salvar a revisão de ninho.';

  @override
  String get findSpecimens => 'Procurar espécimes...';

  @override
  String get noSpecimenCollected => 'Nenhum espécime coletado.';

  @override
  String get newSpecimen => 'Novo espécime';

  @override
  String get deleteSpecimen => 'Apagar espécime';

  @override
  String get specimenType => 'Tipo de espécime';

  @override
  String get errorSpecimenAlreadyExists =>
      'Já existe um espécime com este número de campo.';

  @override
  String get errorSavingSpecimen => 'Erro ao salvar o espécime.';

  @override
  String images(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Imagens',
      one: 'Imagem',
    );
    return '$_temp0';
  }

  @override
  String get noImagesFound => 'Nenhuma imagem encontrada.';

  @override
  String get addImage => 'Adicionar imagem';

  @override
  String get gallery => 'Galeria';

  @override
  String get camera => 'Câmera';

  @override
  String get permissionDenied => 'Permissão negada.';

  @override
  String get permissionDeniedPermanently => 'Permissão negada permanentemente.';

  @override
  String get shareImage => 'Compartilhar imagem';

  @override
  String get editImageNotes => 'Editar notas da imagem';

  @override
  String get deleteImage => 'Apagar imagem';

  @override
  String get editNotes => 'Editar notas';

  @override
  String get imageDetails => 'Detalhes da imagem';

  @override
  String inventoryExported(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Inventários exportados!',
      one: 'Inventário exportado!',
    );
    return '$_temp0';
  }

  @override
  String inventoryData(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Dados dos inventários',
      one: 'Dados do inventário',
    );
    return '$_temp0';
  }

  @override
  String errorExportingInventory(int howMany, String errorMessage) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'os inventários',
      one: 'o inventário',
    );
    return 'Erro ao exportar $_temp0: $errorMessage';
  }

  @override
  String nestExported(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Ninhos exportados!',
      one: 'Ninho exportado!',
    );
    return '$_temp0';
  }

  @override
  String nestData(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Dados dos ninhos',
      one: 'Dados do ninho',
    );
    return '$_temp0';
  }

  @override
  String errorExportingNest(int howMany, String errorMessage) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'os ninhos',
      one: 'o ninho',
    );
    return 'Erro ao exportar $_temp0: $errorMessage';
  }

  @override
  String specimenExported(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Espécimes exportados!',
      one: 'Espécime exportado!',
    );
    return '$_temp0';
  }

  @override
  String specimenData(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Dados dos espécimes',
      one: 'Dados do espécime',
    );
    return '$_temp0';
  }

  @override
  String errorExportingSpecimen(int howMany, String errorMessage) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'os espécimes',
      one: 'o espécime',
    );
    return 'Erro ao exportar $_temp0: $errorMessage';
  }

  @override
  String get findSpecies => 'Buscar espécie';

  @override
  String get addSpecies => 'Adicionar espécie';

  @override
  String get deleteSpecies => 'Apagar espécie';

  @override
  String get speciesNotes => 'Anotações da espécie';

  @override
  String get noSpeciesFound => 'Nenhuma espécie registrada';

  @override
  String get speciesName => 'Nome da espécie';

  @override
  String get errorSpeciesAlreadyExists => 'Espécie já adicionada à lista';

  @override
  String get addSpeciesToSample => 'Incluir na amostra';

  @override
  String get removeSpeciesFromSample => 'Remover da amostra';

  @override
  String get reactivateInventory => 'Reativar inventário';

  @override
  String get listFinished => 'Lista concluída';

  @override
  String get listFinishedMessage =>
      'A lista atingiu o número máximo de espécies. Deseja iniciar a próxima lista ou encerrar?';

  @override
  String get startNextList => 'Iniciar próxima lista';

  @override
  String get editSpecimen => 'Editar espécime';

  @override
  String get editNest => 'Editar ninho';

  @override
  String get editNestRevision => 'Editar revisão de ninho';

  @override
  String get editEgg => 'Editar ovo';

  @override
  String get editWeather => 'Editar dados do tempo';

  @override
  String get editVegetation => 'Editar dados de vegetação';

  @override
  String get editInventoryId => 'Editar ID';

  @override
  String get confirmDeleteSpecies => 'Remover espécie';

  @override
  String confirmDeleteSpeciesMessage(String speciesName) {
    return 'Deseja remover a espécie $speciesName dos outros inventários ativos?';
  }

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get newJournalEntry => 'Nova nota';

  @override
  String get sortByLastModified => 'Ordenar por última modificação';

  @override
  String get sortByTitle => 'Ordenar por título';

  @override
  String get findJournalEntries => 'Procurar notas';

  @override
  String get noJournalEntriesFound => 'Nenhuma nota encontrada';

  @override
  String get title => 'Título';

  @override
  String get insertTitle => 'Insira um título para a nota';

  @override
  String get errorSavingJournalEntry =>
      'Erro ao salvar a nota do diário de campo';

  @override
  String get deleteJournalEntry => 'Apagar nota';

  @override
  String get editJournalEntry => 'Editar nota';

  @override
  String get statistics => 'Estatísticas';

  @override
  String get selectSpeciesToShowStats =>
      'Selecione uma espécie para ver as estatísticas';

  @override
  String get perSpecies => 'Por espécie';

  @override
  String get totalRecords => 'Total de registros';

  @override
  String get recordsPerMonth => 'Registros por mês';

  @override
  String get recordsPerYear => 'Registros por ano';

  @override
  String get addCoordinates => 'Adicionar coordenadas';

  @override
  String get recordedSpecies => 'espécies registradas';

  @override
  String get topTenSpecies => 'Top 10 espécies mais registradas';

  @override
  String get surveyHours => 'horas de amostragem';

  @override
  String get averageSurveyHours => 'horas de amostragem por inventário';

  @override
  String get pending => 'Pendentes';

  @override
  String get archived => 'Arquivados';

  @override
  String get archiveSpecimen => 'Arquivar espécime';

  @override
  String get maleNameOrId => 'Nome ou ID do macho';

  @override
  String get femaleNameOrId => 'Nome ou ID da fêmea';

  @override
  String get helpersNamesOrIds => 'Nomes ou IDs dos ajudantes';

  @override
  String get plantSpeciesOrSupportType => 'Espécie vegetal ou tipo de suporte';

  @override
  String get formatNumbersDescription =>
      'Desmarque para formatar números com ponto como separador decimal';

  @override
  String get selectAll => 'Selecionar todos';

  @override
  String get exporting => 'Exportando...';

  @override
  String get noDataToExport => 'Sem dados para exportar.';

  @override
  String get exportingPleaseWait => 'Exportando, aguarde...';

  @override
  String get errorTitle => 'Erro';

  @override
  String get warningTitle => 'Aviso';

  @override
  String get remindMissingVegetationData =>
      'Lembrar dados faltantes de vegetação';

  @override
  String get remindMissingWeatherData => 'Lembrar dados faltantes do tempo';

  @override
  String get missingVegetationData => 'Não há dados de vegetação.';

  @override
  String get missingWeatherData => 'Não há dados do tempo.';

  @override
  String get addButton => 'Adicionar';

  @override
  String get ignoreButton => 'Ignorar';

  @override
  String get observerAbbreviationMissing =>
      'Sigla do observador não encontrada. Adicione-a nas configurações.';

  @override
  String get invalidNumericValue => 'Valor inválido';

  @override
  String get nestRevisionsMissing =>
      'Não há revisões para este ninho. Adicione ao menos uma revisão.';

  @override
  String get editLocality => 'Editar localidade';

  @override
  String get addEditNotes => 'Adicionar/editar anotações';

  @override
  String get exportKml => 'Exportar KML';

  @override
  String get edit => 'Editar';

  @override
  String get noPoisToExport => 'Nenhum POI para exportar.';

  @override
  String get totalSpeciesWithinSample => 'Espécies na amostra';

  @override
  String get details => 'Detalhes';

  @override
  String get editInventoryDetails => 'Detalhes do inventário';

  @override
  String get discardedInventory => 'Inventário descartado';

  @override
  String errorImportingInventoryWithFormatError(String errorMessage) {
    return 'Erro de formato ao importar inventário: $errorMessage';
  }

  @override
  String inventoriesImportedSuccessfully(int howMany) {
    return 'Inventários importados com sucesso: $howMany';
  }

  @override
  String importCompletedWithErrors(
    int successfullyImportedCount,
    int importErrorsCount,
  ) {
    return 'Importação concluída com erros: $successfullyImportedCount com sucesso, $importErrorsCount erros';
  }

  @override
  String failedToImportInventoryWithId(String id) {
    return 'Falha ao importar inventário com ID: $id';
  }

  @override
  String get invalidJsonFormatExpectedObjectOrArray =>
      'Formato JSON inválido. Esperado um objeto ou uma lista.';

  @override
  String get importingNests => 'Importando ninhos';

  @override
  String get errorImportingNests => 'Erro importando ninhos';

  @override
  String errorImportingNestsWithFormatError(String errorMessage) {
    return 'Erro de formato importando ninho: $errorMessage';
  }

  @override
  String nestsImportedSuccessfully(int howMany) {
    return 'Ninhos importados com sucesso: $howMany';
  }

  @override
  String failedToImportNestWithId(int id) {
    return 'Falha ao importar ninho com ID: $id';
  }

  @override
  String get backup => 'Backup';

  @override
  String get createBackup => 'Criar backup';

  @override
  String get sendBackupTo => 'Enviar backup para...';

  @override
  String get backupCreatedAndSharedSuccessfully =>
      'Backup criado e compartilhado com sucesso';

  @override
  String get errorCreatingBackup => 'Erro criando backup';

  @override
  String get errorBackupNotFound => 'Backup não encontrado';

  @override
  String get restoreBackup => 'Restaurar backup';

  @override
  String get backupRestoredSuccessfully =>
      'Backup restaurado com sucesso! Reinicie o app para aplicar as alterações.';

  @override
  String get errorRestoringBackup => 'Erro restaurando backup';

  @override
  String get backingUpData => 'Criando backup dos dados';

  @override
  String get restoringData => 'Restaurando dados';

  @override
  String get importingSpecimens => 'Importando espécimes';

  @override
  String get errorImportingSpecimens => 'Erro importando espécimes';

  @override
  String errorImportingSpecimensWithFormatError(String errorMessage) {
    return 'Erro de formato importando espécime: $errorMessage';
  }

  @override
  String specimensImportedSuccessfully(int howMany) {
    return 'Espécimes importados com sucesso: $howMany';
  }

  @override
  String failedToImportSpecimenWithId(int id) {
    return 'Falha ao importar espécime com ID: $id';
  }

  @override
  String get cloudCoverRangeError => 'Nebulosidade deve estar entre 0 e 100';

  @override
  String get relativeHumidityRangeError =>
      'Umidade relativa deve estar entre 0 e 100';

  @override
  String get atmosphericPressure => 'Pressão atmosférica';

  @override
  String get relativeHumidity => 'Umidade relativa';

  @override
  String get totalOfObservers => 'Total de observadores';

  @override
  String get enterCoordinates => 'Entrar coordenadas';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get invalidLatitude => 'Latitude inválida';

  @override
  String get invalidLongitude => 'Longitude inválida';

  @override
  String get fieldCannotBeEmpty => 'Campo deve ser preenchido';

  @override
  String get locationError => 'Erro de localização';

  @override
  String get couldNotGetGpsLocation =>
      'Não foi possível obter a localização do GPS';

  @override
  String get continueWithout => 'Continuar sem';

  @override
  String get enterManually => 'Entrar manualmente';

  @override
  String get distance => 'Distância';

  @override
  String get flightHeight => 'Altura de voo';

  @override
  String get flightDirection => 'Direção de voo';

  @override
  String get insertCount => 'Insira a contagem';

  @override
  String get insertValidNumber => 'Insira um número válido';

  @override
  String get windDirection => 'Direção do vento';

  @override
  String get reactivate => 'Reativar';

  @override
  String get archive => 'Arquivar';

  @override
  String get platinumSponsor => 'Patrocinador Platina';

  @override
  String get changelog => 'Log de alterações';

  @override
  String get viewLicense => 'Ver licença';

  @override
  String get openSourceLicenses => 'Licenças de código aberto';

  @override
  String get precipitationNone => 'Nenhuma';

  @override
  String get precipitationFog => 'Névoa';

  @override
  String get precipitationMist => 'Neblina';

  @override
  String get precipitationDrizzle => 'Garoa';

  @override
  String get precipitationRain => 'Chuva';

  @override
  String get precipitationShowers => 'Pancadas';

  @override
  String get precipitationSnow => 'Neve';

  @override
  String get precipitationHail => 'Granizo';

  @override
  String get precipitationFrost => 'Geada';

  @override
  String get distributionNone => 'Nada';

  @override
  String get distributionRare => 'Rara';

  @override
  String get distributionFewSparseIndividuals => 'Poucos indivíduos esparsos';

  @override
  String get distributionOnePatch => 'Uma mancha';

  @override
  String get distributionOnePatchFewSparseIndividuals =>
      'Uma mancha e indivíduos isolados';

  @override
  String get distributionManySparseIndividuals => 'Vários indivíduos esparsos';

  @override
  String get distributionOnePatchManySparseIndividuals =>
      'Mancha e vários indivíduos isolados';

  @override
  String get distributionFewPatches => 'Poucas manchas';

  @override
  String get distributionFewPatchesSparseIndividuals =>
      'Poucas manchas e indivíduos isolados';

  @override
  String get distributionManyPatches => 'Várias manchas equidistantes';

  @override
  String get distributionManyPatchesSparseIndividuals =>
      'Várias manchas e indivíduos dispersos';

  @override
  String get distributionHighDensityIndividuals =>
      'Indivíduos isolados em alta densidade';

  @override
  String get distributionContinuousCoverWithGaps =>
      'Contínua com manchas sem cobertura';

  @override
  String get distributionContinuousDenseCover => 'Contínua e densa';

  @override
  String get distributionContinuousDenseCoverWithEdge =>
      'Contínua com borda separando estratos';

  @override
  String get inventoryFreeQualitative => 'Lista Qualitativa Livre';

  @override
  String get inventoryTimedQualitative => 'Lista Qualitativa Temporizada';

  @override
  String get inventoryIntervalQualitative => 'Lista Qualitativa por Intervalos';

  @override
  String get inventoryMackinnonList => 'Lista de Mackinnon';

  @override
  String get inventoryTransectCount => 'Contagem em Transecto';

  @override
  String get inventoryPointCount => 'Ponto de Contagem';

  @override
  String get inventoryBanding => 'Anilhamento';

  @override
  String get inventoryCasual => 'Observação Casual';

  @override
  String get inventoryTransectDetection => 'Transecto de Detecções';

  @override
  String get inventoryPointDetection => 'Ponto de Detecções';

  @override
  String get eggShapeSpherical => 'Esférico';

  @override
  String get eggShapeElliptical => 'Elíptico';

  @override
  String get eggShapeOval => 'Oval';

  @override
  String get eggShapePyriform => 'Piriforme';

  @override
  String get eggShapeConical => 'Cônico';

  @override
  String get eggShapeBiconical => 'Bicônico';

  @override
  String get eggShapeCylindrical => 'Cilíndrico';

  @override
  String get eggShapeLongitudinal => 'Longitudinal';

  @override
  String get nestStageUnknown => 'Indeterminado';

  @override
  String get nestStageBuilding => 'Construção';

  @override
  String get nestStageLaying => 'Postura';

  @override
  String get nestStageIncubating => 'Incubação';

  @override
  String get nestStageHatching => 'Eclosão';

  @override
  String get nestStageNestling => 'Ninhego';

  @override
  String get nestStageInactive => 'Inativo';

  @override
  String get nestStatusUnknown => 'Indeterminado';

  @override
  String get nestStatusActive => 'Ativo';

  @override
  String get nestStatusInactive => 'Inativo';

  @override
  String get nestFateUnknown => 'Indeterminado';

  @override
  String get nestFateLost => 'Perdido';

  @override
  String get nestFateSuccess => 'Sucesso';

  @override
  String get specimenWholeCarcass => 'Carcaça inteira';

  @override
  String get specimenPartialCarcass => 'Carcaça parcial';

  @override
  String get specimenNest => 'Ninho';

  @override
  String get specimenBones => 'Ossos';

  @override
  String get specimenEgg => 'Ovo';

  @override
  String get specimenParasites => 'Parasitas';

  @override
  String get specimenFeathers => 'Penas';

  @override
  String get specimenBlood => 'Sangue';

  @override
  String get specimenClaw => 'Garra';

  @override
  String get specimenSwab => 'Swab';

  @override
  String get specimenTissues => 'Tecidos';

  @override
  String get specimenFeces => 'Fezes';

  @override
  String get specimenRegurgite => 'Regurgito';
}
