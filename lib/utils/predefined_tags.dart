/// Returns localized predefined journal tag names for the app locale.
List<String> localizedPredefinedTagNames(String languageCode) {
  if (languageCode.toLowerCase().startsWith('pt')) {
    return const [
      'comportamento',
      'alimentação',
      'vocalização',
      'identificação',
      'dúvida',
      'habitat',
      'clima',
      'lista',
      'reprodução',
      'chegada sazonal',
      'trabalho de campo',
    ];
  }

  return const [
    'behavior',
    'feeding',
    'vocalization',
    'identification',
    'doubt',
    'habitat',
    'weather',
    'list',
    'breeding',
    'season arrival',
    'fieldwork',
  ];
}
