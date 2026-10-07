import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/inventory.dart';

/// Paleta de Cores e Tokens do Relatório Impresso do Xolmis Mobile
class PdfReportColors {
  static const PdfColor slate900 = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor slate800 = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor slate700 = PdfColor.fromInt(0xFF334155);
  static const PdfColor slate500 = PdfColor.fromInt(0xFF64748B);
  static const PdfColor slate200 = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor slate100 = PdfColor.fromInt(0xFFF1F5F9);

  static const PdfColor jacarandaDeep = PdfColor.fromInt(0xFF3A357C);
  static const PdfColor jacarandaHighlight = PdfColor.fromInt(0xFFF0F2FF);
  static const PdfColor jacarandaBorder = PdfColor.fromInt(0xFFC7D2FE);
  static const PdfColor folhaCampo = PdfColor.fromInt(0xFF2A633D);
  static const PdfColor terraMadeira = PdfColor.fromInt(0xFF6E523C);
}


/// Estrutura auxiliar para cálculo da Matriz Comparativa de Espécies x Inventários
class SpeciesMatrixRow {
  final String speciesName;
  final List<int> countsPerInventory;
  final int total;

  SpeciesMatrixRow({
    required this.speciesName,
    required this.countsPerInventory,
    required this.total,
  });
}

/// Serviço responsável por calcular métricas e gerar o documento PDF A4 nativo
class SelectedInventoryPdfReportService {
  /// Gera o arquivo em bytes do relatório PDF pronto para salvar/imprimir/compartilhar
  static Future<Uint8List> generatePdf({
    required List<Inventory> inventories,
    String observerName = 'Carlos B. (CB)',
    String projectName = 'Pampa / Restinga 2026',
  }) async {
    final pdf = pw.Document(
      title: 'Xolmis - Relatório de Inventários Selecionados',
      author: observerName,
    );

    // Carregamento de fontes padrão para garantir renderização idêntica em todos os SOs
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontItalic = await PdfGoogleFonts.interItalic();
    final fontMono = await PdfGoogleFonts.firaCodeRegular();
    final fontMonoBold = await PdfGoogleFonts.firaCodeBold();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

    // Preparações estatísticas
    final speciesMatrix = _buildSpeciesMatrix(inventories);
    final totalRichness = _calculateTotalRichness(inventories);
    final avgRichness = inventories.isNotEmpty
        ? (inventories.fold<int>(0, (sum, inv) => sum + _getSpeciesRichness(inv)) / inventories.length)
        : 0.0;
    final distinctLocalities = inventories.map((i) => i.localityName).toSet().length;
    final hourlyRecords = _calculateHourlyOccurrences(inventories);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        header: (pw.Context context) => _buildPdfHeader(
          observerName: observerName,
          projectName: projectName,
          totalListas: inventories.length,
          fontMono: fontMono,
        ),
        footer: (pw.Context context) => _buildPdfFooter(
          currentPage: context.pageNumber,
          totalPages: context.pagesCount,
          fontMono: fontMono,
        ),
        build: (pw.Context context) => [
          pw.SizedBox(height: 12),

          _buildKpiMetricsGrid(
            inventoriesCount: inventories.length,
            localitiesCount: distinctLocalities,
            totalRichness: totalRichness,
            avgRichness: avgRichness,
            fontMonoBold: fontMonoBold,
          ),
          pw.SizedBox(height: 16),

          _buildInventoriesTable(
            inventories: inventories,
            fontMono: fontMono,
            fontMonoBold: fontMonoBold,
          ),
          pw.SizedBox(height: 16),

          _buildChartsSection(
            inventories: inventories,
            hourlyRecords: hourlyRecords,
            fontMono: fontMono,
          ),
          pw.SizedBox(height: 16),

          _buildSpeciesMatrixTable(
            inventories: inventories,
            matrixRows: speciesMatrix,
            fontMono: fontMono,
            fontMonoBold: fontMonoBold,
          ),
          pw.SizedBox(height: 20),

          _buildSignatureBlock(observerName: observerName),
        ],
      ),
    );

    return pdf.save();
  }

  // Header institucional do relatório
  static pw.Widget _buildPdfHeader({
    required String observerName,
    required String projectName,
    required int totalListas,
    required pw.Font fontMono,
  }) {
    final now = DateTime.now();
    final formattedDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfReportColors.slate900, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 22,
                    height: 22,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      color: PdfReportColors.slate900,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'X',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    'XOLMIS',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfReportColors.slate900,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: PdfReportColors.slate100,
                      borderRadius: pw.BorderRadius.circular(3),
                      border: pw.Border.all(color: PdfReportColors.slate200),
                    ),
                    child: pw.Text(
                      'ORNITHOLOGY FIELD DATA',
                      style: pw.TextStyle(
                        font: fontMono,
                        fontSize: 8,
                        color: PdfReportColors.slate700,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Relatório Técnico: Estatísticas Amostrais',
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfReportColors.slate900,
                ),
              ),
              pw.Text(
                'Análise comparativa e acumulativa dos inventários selecionados',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfReportColors.slate500,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.only(left: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: PdfReportColors.slate200, width: 2),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _buildHeaderMetaRow('Data de Emissão:', formattedDate, fontMono),
                _buildHeaderMetaRow('Observador:', observerName, fontMono),
                _buildHeaderMetaRow('Projeto:', projectName, fontMono),
                _buildHeaderMetaRow('Total de Listas:', '$totalListas Amostragens', fontMono),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderMetaRow(String label, String value, pw.Font fontMono) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          style: pw.TextStyle(font: fontMono, fontSize: 8),
          children: [
            pw.TextSpan(text: '$label ', style: const pw.TextStyle(color: PdfReportColors.slate500)),
            pw.TextSpan(text: value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfReportColors.slate800)),
          ],
        ),
      ),
    );
  }

  // Grid de Métricas Principais (KPIs)
  static pw.Widget _buildKpiMetricsGrid({
    required int inventoriesCount,
    required int localitiesCount,
    required int totalRichness,
    required double avgRichness,
    required pw.Font fontMonoBold,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SUMÁRIO AMOSTRAL DE INDICADORES',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfReportColors.slate700,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            _buildKpiCard('Inventários', '$inventoriesCount', 'listas selecionadas', fontMonoBold),
            pw.SizedBox(width: 8),
            _buildKpiCard('Localidades', '$localitiesCount', 'locais distintos', fontMonoBold),
            pw.SizedBox(width: 8),
            _buildKpiCard('Riqueza Total', '$totalRichness', 'espécies únicas', fontMonoBold),
            pw.SizedBox(width: 8),
            _buildKpiCard('Riqueza Média', avgRichness.toStringAsFixed(1), 'esp. / inventário', fontMonoBold),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildKpiCard(String label, String value, String subtext, pw.Font fontMonoBold) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfReportColors.slate200),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: const pw.TextStyle(fontSize: 7, color: PdfReportColors.slate500),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                font: fontMonoBold,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfReportColors.slate900,
              ),
            ),
            pw.Text(
              subtext,
              style: const pw.TextStyle(fontSize: 7, color: PdfReportColors.slate500),
            ),
          ],
        ),
      ),
    );
  }

  // Tabela de Inventários Selecionados
  static pw.Widget _buildInventoriesTable({
    required List<Inventory> inventories,
    required pw.Font fontMono,
    required pw.Font fontMonoBold,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INVENTÁRIOS ANALISADOS NESTE RELATÓRIO',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfReportColors.slate700,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfReportColors.slate200, width: 0.8),
          children: [
            // Header Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfReportColors.slate100),
              children: [
                _buildTableCell('ID do Inventário', isHeader: true, fontMono: fontMonoBold),
                _buildTableCell('Tipo de Método', isHeader: true),
                _buildTableCell('Localidade', isHeader: true),
                _buildTableCell('Data / Horário', isHeader: true, fontMono: fontMonoBold),
                _buildTableCell('Espécies', isHeader: true, alignRight: true, fontMono: fontMonoBold),
              ],
            ),
            // Data Rows
            ...inventories.asMap().entries.map((entry) {
              final idx = entry.key;
              final inv = entry.value;
              final shortLabel = 'P${(idx + 1).toString().padLeft(2, '0')}';
              final richness = _getSpeciesRichness(inv);

              final startTimeStr = inv.startTime != null
                  ? '${inv.startTime!.day.toString().padLeft(2, '0')}/${inv.startTime!.month.toString().padLeft(2, '0')} ${inv.startTime!.hour.toString().padLeft(2, '0')}:${inv.startTime!.minute.toString().padLeft(2, '0')}'
                  : 'N/A';

              return pw.TableRow(
                children: [
                  _buildTableCell('${inv.id} ($shortLabel)', fontMono: fontMonoBold),
                  _buildTableCell(inv.type?.toString().split('.').last ?? 'Contagem'),
                  _buildTableCell(inv.localityName ?? 'Não informada'),
                  _buildTableCell(startTimeStr, fontMono: fontMono),
                  _buildTableCell('$richness spp', alignRight: true, fontMono: fontMonoBold),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // Gráficos Vetoriais Nativos desenhados via Canvas do PDF
  static pw.Widget _buildChartsSection({
    required List<Inventory> inventories,
    required Map<int, int> hourlyRecords,
    required pw.Font fontMono,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Chart 1: Curva de Acumulação Vetorial
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfReportColors.slate200),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Curva de Acumulação de Espécies',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.SizedBox(
                  height: 100,
                  child: pw.CustomPaint(
                    painter: (PdfGraphics canvas, PdfPoint size) {
                      _drawAccumulationChart(canvas, size, inventories);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),

        // Chart 2: Histograma de Atividade por Hora (24h)
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfReportColors.slate200),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Atividade por Hora do Dia (24h)',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.SizedBox(
                  height: 100,
                  child: pw.CustomPaint(
                    painter: (PdfGraphics canvas, PdfPoint size) {
                      _drawHourlyBarChart(canvas, size, hourlyRecords);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Matriz Comparativa Espécie x Inventário
  static pw.Widget _buildSpeciesMatrixTable({
    required List<Inventory> inventories,
    required List<SpeciesMatrixRow> matrixRows,
    required pw.Font fontMono,
    required pw.Font fontMonoBold,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'MATRIZ COMPARATIVA DE ESPÉCIES X INVENTÁRIOS',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfReportColors.slate700,
              ),
            ),
            pw.Text(
              '* Destaque sombreado indica 1ª ocorrência da espécie',
              style: pw.TextStyle(font: fontMono, fontSize: 7, color: PdfReportColors.slate500),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfReportColors.slate200, width: 0.8),
          children: [
            // Table Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfReportColors.slate100),
              children: [
                _buildTableCell('Táxon / Espécie', isHeader: true, isItalic: true),
                ...List.generate(
                  inventories.length,
                      (i) => _buildTableCell('P${(i + 1).toString().padLeft(2, '0')}', isHeader: true, alignCenter: true, fontMono: fontMonoBold),
                ),
                _buildTableCell('Total', isHeader: true, alignRight: true, fontMono: fontMonoBold),
              ],
            ),

            // Table Data Rows
            ...matrixRows.map((row) {
              return pw.TableRow(
                children: [
                  _buildTableCell(row.speciesName, isItalic: true),
                  ...List.generate(inventories.length, (invIndex) {
                    final count = row.countsPerInventory[invIndex];
                    final isFirstOccurrence = (count > 0) &&
                        row.countsPerInventory.take(invIndex).every((c) => c == 0);

                    return _buildTableCell(
                      count > 0 ? '$count' : '-',
                      alignCenter: true,
                      fontMono: isFirstOccurrence ? fontMonoBold : fontMono,
                      isHighlighted: isFirstOccurrence,
                    );
                  }),
                  _buildTableCell('${row.total}', alignRight: true, fontMono: fontMonoBold),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // Bloco de Assinatura e Validação Técnica
  static pw.Widget _buildSignatureBlock({required String observerName}) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfReportColors.slate200, width: 1)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Declaração do Pesquisador:',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Atesto que os dados apresentados neste relatório foram coletados segundo a metodologia especificada nos formulários padrão do Xolmis Mobile.',
                  style: const pw.TextStyle(fontSize: 7, color: PdfReportColors.slate500),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 160,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfReportColors.slate700, width: 0.8)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.SizedBox(height: 4),
                      pw.Text(
                        observerName,
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Pesquisador Responsável',
                        style: const pw.TextStyle(fontSize: 7, color: PdfReportColors.slate500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Validação Institucional:',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Curadoria de dados e verificação ornitológica realizada em conformidade com as diretrizes do projeto.',
                  style: const pw.TextStyle(fontSize: 7, color: PdfReportColors.slate500),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 160,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfReportColors.slate700, width: 0.8)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Curadoria Xolmis Platform',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Assinatura / Carimbo de Validação',
                        style: const pw.TextStyle(fontSize: 7, color: PdfReportColors.slate500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rodapé do Documento A4
  static pw.Widget _buildPdfFooter({
    required int currentPage,
    required int totalPages,
    required pw.Font fontMono,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfReportColors.slate200, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gerado via Xolmis Mobile v1.0.2 — Sistema Integrado Ornitológico',
            style: pw.TextStyle(font: fontMono, fontSize: 7, color: PdfReportColors.slate500),
          ),
          pw.Text(
            'Página $currentPage de $totalPages',
            style: pw.TextStyle(font: fontMono, fontSize: 7, color: PdfReportColors.slate500),
          ),
        ],
      ),
    );
  }

  // Auxiliar para Células de Tabela do PDF
  static pw.Widget _buildTableCell(
      String text, {
        bool isHeader = false,
        bool alignCenter = false,
        bool alignRight = false,
        bool isItalic = false,
        bool isHighlighted = false,
        pw.Font? fontMono,
      }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      color: isHighlighted ? PdfReportColors.jacarandaHighlight : null,
      alignment: alignCenter
          ? pw.Alignment.center
          : (alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: fontMono,
          fontSize: isHeader ? 8 : 7.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
          color: isHeader ? PdfReportColors.slate900 : PdfReportColors.slate800,
        ),
      ),
    );
  }

  // Pintura da Curva de Acumulação em Canvas do PDF
  static void _drawAccumulationChart(PdfGraphics canvas, PdfPoint size, List<Inventory> inventories) {
    if (inventories.isEmpty) return;

    final width = size.x;
    final height = size.y;

    // Eixos
    canvas.setColor(PdfReportColors.slate200);
    canvas.setLineWidth(1);
    canvas.drawLine(0, 0, width, 0);
    canvas.drawLine(0, 0, 0, height);
    canvas.strokePath();

    // Dados simulados/calculados da curva
    final points = <PdfPoint>[];
    double accumulated = 0;
    final seen = <String>{};

    for (int i = 0; i < inventories.length; i++) {
      for (final s in inventories[i].speciesList) {
        seen.add(s.name);
      }
      accumulated = seen.length.toDouble();

      final px = (i / (inventories.length - 1 == 0 ? 1 : inventories.length - 1)) * (width - 10) + 5;
      final py = (accumulated / 100.0) * (height - 10) + 5;
      points.add(PdfPoint(px, py));
    }

    // Desenha Linha de Acumulação
    if (points.length > 1) {
      canvas.setColor(PdfReportColors.slate900);
      canvas.setLineWidth(1.5);
      canvas.moveTo(points.first.x, points.first.y);
      for (int i = 1; i < points.length; i++) {
        canvas.lineTo(points[i].x, points[i].y);
      }
      canvas.strokePath();

      // Desenha pontos
      for (final p in points) {
        canvas.setFillColor(PdfReportColors.slate900);
        canvas.drawEllipse(p.x, p.y, 2, 2);
        canvas.fillPath();
      }
    }
  }

  // Pintura do Histograma de Horas em Canvas do PDF
  static void _drawHourlyBarChart(PdfGraphics canvas, PdfPoint size, Map<int, int> hourlyRecords) {
    final width = size.x;
    final height = size.y;
    final barWidth = width / 24;

    int maxVal = 1;
    hourlyRecords.forEach((_, count) {
      if (count > maxVal) maxVal = count;
    });

    for (int hour = 0; hour < 24; hour++) {
      final count = hourlyRecords[hour] ?? 0;
      final barHeight = (count / maxVal) * (height - 10);
      final x = hour * barWidth;

      if (count > 0) {
        canvas.setFillColor(PdfReportColors.slate700);
        canvas.drawRect(x + 1, 0, barWidth - 2, barHeight);
        canvas.fillPath();
      }
    }

    // Linha de base
    canvas.setColor(PdfReportColors.slate200);
    canvas.setLineWidth(1);
    canvas.drawLine(0, 0, width, 0);
    canvas.strokePath();
  }

  // Lógicas de Extração de Métricas
  static List<SpeciesMatrixRow> _buildSpeciesMatrix(List<Inventory> inventories) {
    final speciesMap = <String, List<int>>{};

    for (int i = 0; i < inventories.length; i++) {
      final inv = inventories[i];
      for (final s in inv.speciesList) {
        speciesMap.putIfAbsent(s.name, () => List.filled(inventories.length, 0));
        speciesMap[s.name]![i] += 1;
      }
    }

    final sortedSpecies = speciesMap.keys.toList()..sort();

    return sortedSpecies.map((species) {
      final counts = speciesMap[species]!;
      final total = counts.reduce((a, b) => a + b);
      return SpeciesMatrixRow(
        speciesName: species,
        countsPerInventory: counts,
        total: total,
      );
    }).toList();
  }

  static int _calculateTotalRichness(List<Inventory> inventories) {
    final speciesSet = <String>{};
    for (final inv in inventories) {
      for (final s in inv.speciesList) {
        speciesSet.add(s.name);
      }
    }
    return speciesSet.length;
  }

  static int _getSpeciesRichness(Inventory inventory) {
    if (inventory.speciesCount > 0) return inventory.speciesCount;
    return inventory.speciesList.map((s) => s.name).toSet().length;
  }

  static Map<int, int> _calculateHourlyOccurrences(List<Inventory> inventories) {
    final Map<int, int> occurrences = {for (var i = 0; i < 24; i++) i: 0};
    for (final inv in inventories) {
      for (final s in inv.speciesList) {
        final time = s.sampleTime ?? inv.startTime;
        if (time != null) {
          occurrences[time.hour] = (occurrences[time.hour] ?? 0) + 1;
        }
      }
    }
    return occurrences;
  }
}


/// Tela Flutter de Pré-visualização e Impressão do Relatório A4
class InventoryPdfReportPreviewScreen extends StatelessWidget {
  final List<Inventory> inventories;

  const InventoryPdfReportPreviewScreen({
    super.key,
    required this.inventories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pré-visualização do Relatório A4'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final pdfBytes = await SelectedInventoryPdfReportService.generatePdf(
                inventories: inventories,
              );
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: 'Relatorio_Xolmis_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => SelectedInventoryPdfReportService.generatePdf(
          inventories: inventories,
        ),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName: 'Relatorio_Tecnico_Xolmis.pdf',
      ),
    );
  }
}