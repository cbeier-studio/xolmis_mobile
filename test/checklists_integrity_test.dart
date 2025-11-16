import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xolmis/core/core_consts.dart'; // Importe onde seu enum está definido
import 'dart:convert';

void main() {
  // Inicializa o binding do Flutter para que possamos usar o rootBundle nos testes.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Data Integrity Tests -', () {

    test('Cada país suportado deve ter um arquivo de espécies JSON válido', () async {
      // 1. Obtém a lista de todos os países definidos no enum.
      final allCountries = SupportedCountry.values;

      // Garante que o enum não está vazio para o teste ser significativo.
      expect(allCountries, isNotEmpty, reason: 'O enum SupportedCountry não pode estar vazio.');

      print('Iniciando verificação para ${allCountries.length} países...');

      // 2. Itera sobre cada país para verificar seu arquivo correspondente.
      for (final country in allCountries) {
        final countryCode = country.name; // Obtém a sigla (ex: "BR")
        final filePath = 'assets/checklists/species_data_$countryCode.json';

        print('Verificando arquivo para $countryCode em: $filePath');

        String? jsonString;
        try {
          // 3. Tenta carregar o arquivo JSON do bundle de assets.
          jsonString = await rootBundle.loadString(filePath);

          // Testa se o arquivo não está vazio.
          expect(jsonString, isNotNull, reason: 'O arquivo para $countryCode não foi encontrado em $filePath.');
          expect(jsonString, isNotEmpty, reason: 'O arquivo para $countryCode está vazio.');

        } catch (e) {
          // Se rootBundle.loadString falhar, o teste falha com uma mensagem clara.
          fail('FALHA: Não foi possível carregar o arquivo para o país $countryCode em "$filePath". Erro: $e');
        }

        // 4. Se o arquivo foi carregado, tenta decodificar o JSON.
        try {
          final jsonData = json.decode(jsonString) as List<dynamic>;

          // Opcional, mas recomendado: verifica se a lista não está vazia.
          expect(jsonData, isNotEmpty, reason: 'A lista de espécies para $countryCode está vazia.');

          // Opcional, mas recomendado: verifica a estrutura do primeiro item.
          final firstItem = jsonData.first as Map<String, dynamic>;
          expect(firstItem.containsKey('scientificName'), isTrue, reason: 'O primeiro item no JSON de $countryCode não contém a chave "scientificName".');

          print('SUCESSO: Arquivo para $countryCode carregado e validado com sucesso.');

        } catch (e) {
          // Se json.decode ou as verificações de tipo falharem, o teste falha.
          fail('FALHA: O arquivo para o país $countryCode em "$filePath" não é um JSON válido ou não segue a estrutura esperada. Erro: $e');
        }
      }
    });

  });
}
