import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import "package:image/image.dart" as img;
import "package:pdfrx/pdfrx.dart" as pdfrx;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  /// Öffnet ein PDF-Dokument.
  PdfDocument open(String path) {
    try {
      final bytes = File(path).readAsBytesSync();
      return PdfDocument(inputBytes: bytes);
    } catch (error) {
      if (error.toString().toLowerCase().contains('password')) {
        throw Exception(
          'Diese PDF ist passwortgeschützt und kann derzeit nicht geöffnet werden.',
        );
      }

      rethrow;
    }
  }

  /// Gibt die Anzahl der Seiten zurück.
  int getPageCount(String path) {
    final document = open(path);

    final pageCount = document.pages.count;

    document.dispose();

    return pageCount;
  }

  int getPageCountFromBytes(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);

    final pageCount = document.pages.count;

    document.dispose();

    return pageCount;
  }

  /// Löscht eine einzelne Seite aus einer PDF-Datei.
  ///
  /// pageNumber ist 1-basiert:
  /// Seite 1 = pageNumber 1
  /// Seite 2 = pageNumber 2
  Future<void> deletePage({
    required String inputPath,
    required String outputPath,
    required int pageNumber,
  }) async {
    final document = open(inputPath);

    try {
      if (document.pages.count <= 1) {
        throw Exception(
          'Die letzte Seite eines PDF-Dokuments kann nicht gelöscht werden.',
        );
      }

      if (pageNumber < 1 || pageNumber > document.pages.count) {
        throw RangeError('Ungültige Seitennummer: $pageNumber');
      }

      final pageIndex = pageNumber - 1;

      document.pages.removeAt(pageIndex);

      final bytes = await document.save();

      await File(outputPath).writeAsBytes(bytes);
    } finally {
      document.dispose();
    }
  }

  /// Dreht eine einzelne PDF-Seite um 90 Grad im Uhrzeigersinn.
  Future<void> rotatePage({
    required String inputPath,
    required String outputPath,
    required int pageNumber,
  }) async {
    final document = open(inputPath);

    try {
      if (pageNumber < 1 || pageNumber > document.pages.count) {
        throw RangeError('Ungültige Seitennummer: $pageNumber');
      }

      final page = document.pages[pageNumber - 1];

      switch (page.rotation) {
        case PdfPageRotateAngle.rotateAngle0:
          page.rotation = PdfPageRotateAngle.rotateAngle90;
          break;
        case PdfPageRotateAngle.rotateAngle90:
          page.rotation = PdfPageRotateAngle.rotateAngle180;
          break;
        case PdfPageRotateAngle.rotateAngle180:
          page.rotation = PdfPageRotateAngle.rotateAngle270;
          break;
        case PdfPageRotateAngle.rotateAngle270:
          page.rotation = PdfPageRotateAngle.rotateAngle0;
          break;
      }

      final bytes = await document.save();
      await File(outputPath).writeAsBytes(bytes);
    } finally {
      document.dispose();
    }
  }

  /// Extrahiert eine einzelne Seite in eine neue PDF-Datei.
  Future<void> extractPage({
    required String inputPath,
    required String outputPath,
    required int pageNumber,
  }) async {
    final sourceDocument = open(inputPath);

    try {
      if (pageNumber < 1 || pageNumber > sourceDocument.pages.count) {
        throw RangeError('Ungültige Seitennummer: $pageNumber');
      }

      final sourcePage = sourceDocument.pages[pageNumber - 1];
      final pageSize = sourcePage.size;
      final template = sourcePage.createTemplate();

      final targetDocument = PdfDocument();

      try {
        targetDocument.pageSettings.size = pageSize;
        targetDocument.pageSettings.margins.all = 0;

        final targetPage = targetDocument.pages.add();

        targetPage.graphics.drawPdfTemplate(template, Offset.zero, pageSize);

        final bytes = await targetDocument.save();
        await File(outputPath).writeAsBytes(bytes);
      } finally {
        targetDocument.dispose();
      }
    } finally {
      sourceDocument.dispose();
    }
  }

  /// Extrahiert einen zusammenhängenden Seitenbereich in eine neue PDF-Datei.
  Future<void> extractPageRange({
    required String inputPath,
    required String outputPath,
    required int startPage,
    required int endPage,
  }) async {
    final sourceDocument = open(inputPath);

    try {
      final pageCount = sourceDocument.pages.count;

      if (startPage < 1 ||
          endPage < 1 ||
          startPage > pageCount ||
          endPage > pageCount ||
          startPage > endPage) {
        throw RangeError('Ungültiger Seitenbereich: $startPage bis $endPage');
      }

      final targetDocument = PdfDocument();

      try {
        for (var pageNumber = startPage; pageNumber <= endPage; pageNumber++) {
          final sourcePage = sourceDocument.pages[pageNumber - 1];
          final pageSize = sourcePage.size;
          final template = sourcePage.createTemplate();

          targetDocument.pageSettings.size = pageSize;
          targetDocument.pageSettings.margins.all = 0;

          final targetPage = targetDocument.pages.add();

          targetPage.graphics.drawPdfTemplate(template, Offset.zero, pageSize);
        }

        final bytes = await targetDocument.save();
        await File(outputPath).writeAsBytes(bytes);
      } finally {
        targetDocument.dispose();
      }
    } finally {
      sourceDocument.dispose();
    }
  }

  /// Erstellt ein PDF mit den Seiten in der angegebenen Reihenfolge.
  Future<void> reorderPages({
    required String inputPath,
    required String outputPath,
    required List<int> pageOrder,
  }) async {
    final sourceDocument = open(inputPath);

    try {
      final pageCount = sourceDocument.pages.count;

      if (pageOrder.length != pageCount) {
        throw ArgumentError(
          'Die Seitenreihenfolge muss genau $pageCount Seiten enthalten.',
        );
      }

      final expectedPages = List<int>.generate(pageCount, (index) => index + 1);

      final sortedOrder = [...pageOrder]..sort();

      for (var index = 0; index < pageCount; index++) {
        if (sortedOrder[index] != expectedPages[index]) {
          throw ArgumentError('Die Seitenreihenfolge ist ungültig: $pageOrder');
        }
      }

      final targetDocument = PdfDocument();

      try {
        for (final pageNumber in pageOrder) {
          final sourcePage = sourceDocument.pages[pageNumber - 1];
          final pageSize = sourcePage.size;
          final template = sourcePage.createTemplate();

          targetDocument.pageSettings.size = pageSize;
          targetDocument.pageSettings.margins.all = 0;

          final targetPage = targetDocument.pages.add();

          targetPage.graphics.drawPdfTemplate(template, Offset.zero, pageSize);
        }

        final bytes = await targetDocument.save();
        await File(outputPath).writeAsBytes(bytes);
      } finally {
        targetDocument.dispose();
      }
    } finally {
      sourceDocument.dispose();
    }
  }

  /// Fügt mehrere PDF-Dateien zu einer neuen PDF-Datei zusammen.
  Future<void> mergePdfs({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    if (inputPaths.length < 2) {
      throw ArgumentError(
        'Zum Zusammenführen werden mindestens zwei PDF-Dateien benötigt.',
      );
    }

    final targetDocument = PdfDocument();

    try {
      for (final inputPath in inputPaths) {
        final sourceDocument = open(inputPath);

        try {
          for (var index = 0; index < sourceDocument.pages.count; index++) {
            final sourcePage = sourceDocument.pages[index];
            final pageSize = sourcePage.size;
            final template = sourcePage.createTemplate();

            targetDocument.pageSettings.size = pageSize;
            targetDocument.pageSettings.margins.all = 0;

            final targetPage = targetDocument.pages.add();

            targetPage.graphics.drawPdfTemplate(
              template,
              Offset.zero,
              pageSize,
            );
          }
        } finally {
          sourceDocument.dispose();
        }
      }

      final bytes = await targetDocument.save();
      await File(outputPath).writeAsBytes(bytes);
    } finally {
      targetDocument.dispose();
    }
  }

  /// Erstellt aus einer Bilddatei ein einseitiges PDF.
  Future<void> createPdfFromImage({
    required String imagePath,
    required String outputPath,
  }) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final image = PdfBitmap(imageBytes);
    final document = PdfDocument();

    try {
      final isLandscape = image.width > image.height;

      document.pageSettings.size = PdfPageSize.a4;
      document.pageSettings.orientation = isLandscape
          ? PdfPageOrientation.landscape
          : PdfPageOrientation.portrait;
      document.pageSettings.margins.all = 24;

      final page = document.pages.add();
      final availableSize = page.getClientSize();

      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();
      final scaleX = availableSize.width / imageWidth;
      final scaleY = availableSize.height / imageHeight;
      final scale = scaleX < scaleY ? scaleX : scaleY;

      final drawWidth = imageWidth * scale;
      final drawHeight = imageHeight * scale;
      final x = (availableSize.width - drawWidth) / 2;
      final y = (availableSize.height - drawHeight) / 2;

      page.graphics.drawImage(
        image,
        Rect.fromLTWH(x, y, drawWidth, drawHeight),
      );

      final bytes = await document.save();
      await File(outputPath).writeAsBytes(bytes);
    } finally {
      document.dispose();
    }
  }

  /// Erstellt aus mehreren Bildern eine mehrseitige PDF.
  Future<void> createPdfFromImages({
    required List<String> imagePaths,
    required String outputPath,
  }) async {
    if (imagePaths.isEmpty) {
      throw ArgumentError('Es wurden keine Bilder ausgewählt.');
    }

    final document = PdfDocument();

    try {
      for (final imagePath in imagePaths) {
        final imageBytes = await File(imagePath).readAsBytes();
        final image = PdfBitmap(imageBytes);

        final isLandscape = image.width > image.height;

        document.pageSettings.size = PdfPageSize.a4;
        document.pageSettings.orientation = isLandscape
            ? PdfPageOrientation.landscape
            : PdfPageOrientation.portrait;
        document.pageSettings.margins.all = 24;

        final page = document.pages.add();
        final availableSize = page.getClientSize();

        final imageWidth = image.width.toDouble();
        final imageHeight = image.height.toDouble();

        final scaleX = availableSize.width / imageWidth;
        final scaleY = availableSize.height / imageHeight;
        final scale = scaleX < scaleY ? scaleX : scaleY;

        final drawWidth = imageWidth * scale;
        final drawHeight = imageHeight * scale;

        final x = (availableSize.width - drawWidth) / 2;
        final y = (availableSize.height - drawHeight) / 2;

        page.graphics.drawImage(
          image,
          Rect.fromLTWH(x, y, drawWidth, drawHeight),
        );
      }

      final bytes = await document.save();
      await File(outputPath).writeAsBytes(bytes);
    } finally {
      document.dispose();
    }
  }

  /// Speichert eine einzelne PDF-Seite als PNG-Bild.
  Future<void> exportPageAsPng({
    required String inputPath,
    required String outputPath,
    required int pageNumber,
  }) async {
    final document = await pdfrx.PdfDocument.openFile(inputPath);

    try {
      if (pageNumber < 1 || pageNumber > document.pages.length) {
        throw RangeError("Ungültige Seitennummer: $pageNumber");
      }

      final page = document.pages[pageNumber - 1];

      const scale = 200.0 / 72.0;

      final pageImage = await page.render(
        fullWidth: page.width * scale,
        fullHeight: page.height * scale,
        backgroundColor: 0xFFFFFFFF,
      );

      if (pageImage == null) {
        throw Exception("Seite $pageNumber konnte nicht gerendert werden.");
      }

      try {
        final image = pageImage.createImageNF();
        final pngBytes = img.encodePng(image);

        await File(outputPath).writeAsBytes(pngBytes);
      } finally {
        pageImage.dispose();
      }
    } finally {
      document.dispose();
    }
  }

  /// Erstellt ein PDF-Dokument aus Titel und Fließtext.
  Future<void> createPdfFromText({
    required String outputPath,
    required String title,
    required String deltaJson,
  }) async {
    final document = PdfDocument();

    try {
      document.pageSettings.size = PdfPageSize.a4;
      document.pageSettings.margins.all = 40;

      PdfPage page = document.pages.add();

      final pageWidth = page.getClientSize().width;
      final pageHeight = page.getClientSize().height;

      double y = 0;

      PdfPage newPage() {
        page = document.pages.add();
        y = 0;
        return page;
      }

      if (title.trim().isNotEmpty) {
        final titleFont = PdfStandardFont(
          PdfFontFamily.helvetica,
          18,
          style: PdfFontStyle.bold,
        );

        final result = PdfTextElement(
          text: title.trim(),
          font: titleFont,
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        ).draw(page: page, bounds: Rect.fromLTWH(0, y, pageWidth, 60));

        y = (result?.bounds.bottom ?? 40) + 18;
      }

      final decoded = jsonDecode(deltaJson);

      if (decoded is! List) {
        throw FormatException('Ungültiges Textformat.');
      }

      final paragraphs = <_PdfRichParagraph>[];
      var currentRuns = <_PdfRichRun>[];

      for (final rawOp in decoded) {
        if (rawOp is! Map) {
          continue;
        }

        final insert = rawOp['insert'];

        if (insert is! String) {
          continue;
        }

        final attributesRaw = rawOp['attributes'];
        final attributes = attributesRaw is Map
            ? Map<String, dynamic>.from(attributesRaw)
            : <String, dynamic>{};

        final parts = insert.split('\n');

        for (var i = 0; i < parts.length; i++) {
          final part = parts[i];

          if (part.isNotEmpty) {
            currentRuns.add(
              _PdfRichRun(
                text: part,
                bold: attributes['bold'] == true,
                italic: attributes['italic'] == true,
                underline: attributes['underline'] == true,
                fontFamily: attributes['font']?.toString(),
                fontSize: _pdfFontSizeFromQuill(attributes['size']),
              ),
            );
          }

          if (i < parts.length - 1) {
            paragraphs.add(
              _PdfRichParagraph(
                runs: currentRuns,
                alignment: _pdfAlignmentFromQuill(
                  attributes['align']?.toString(),
                ),
              ),
            );

            currentRuns = <_PdfRichRun>[];
          }
        }
      }

      if (currentRuns.isNotEmpty) {
        paragraphs.add(
          _PdfRichParagraph(
            runs: currentRuns,
            alignment: PdfTextAlignment.left,
          ),
        );
      }

      for (final paragraph in paragraphs) {
        if (paragraph.runs.isEmpty) {
          y += 14;

          if (y > pageHeight - 20) {
            newPage();
          }

          continue;
        }

        final tokens = <_PdfRichToken>[];

        for (final run in paragraph.runs) {
          final pieces = run.text.split(RegExp(r'(\s+)'));

          for (final piece in pieces) {
            if (piece.isEmpty) {
              continue;
            }

            tokens.add(_PdfRichToken(text: piece, run: run));
          }
        }

        var line = <_PdfRichToken>[];
        double lineWidth = 0;

        Future<void> drawLine(
          List<_PdfRichToken> lineTokens, {
          required bool isLastLine,
        }) async {
          if (lineTokens.isEmpty) {
            return;
          }

          double maxHeight = 0;
          double measuredWidth = 0;
          var spaceCount = 0;

          final measurements = <double>[];

          for (final token in lineTokens) {
            final font = _pdfFontForRun(token.run);
            final size = font.measureString(token.text);

            measurements.add(size.width);
            measuredWidth += size.width;

            if (size.height > maxHeight) {
              maxHeight = size.height;
            }

            if (token.text.trim().isEmpty) {
              spaceCount++;
            }
          }

          final lineHeight = maxHeight + 5;

          if (y + lineHeight > pageHeight) {
            newPage();
          }

          double x = 0;
          double extraSpace = 0;

          switch (paragraph.alignment) {
            case PdfTextAlignment.center:
              x = (pageWidth - measuredWidth) / 2;
              break;

            case PdfTextAlignment.right:
              x = pageWidth - measuredWidth;
              break;

            case PdfTextAlignment.justify:
              if (!isLastLine && spaceCount > 0) {
                extraSpace = (pageWidth - measuredWidth) / spaceCount;
              }
              break;

            case PdfTextAlignment.left:
              break;
          }

          for (var i = 0; i < lineTokens.length; i++) {
            final token = lineTokens[i];
            final font = _pdfFontForRun(token.run);
            final width = measurements[i];

            page.graphics.drawString(
              token.text,
              font,
              brush: PdfBrushes.black,
              bounds: Rect.fromLTWH(x, y, width + 3, lineHeight),
            );

            x += width;

            if (token.text.trim().isEmpty) {
              x += extraSpace;
            }
          }

          y += lineHeight;
        }

        for (final token in tokens) {
          final font = _pdfFontForRun(token.run);
          final tokenWidth = font.measureString(token.text).width;

          if (line.isNotEmpty && lineWidth + tokenWidth > pageWidth) {
            await drawLine(List<_PdfRichToken>.from(line), isLastLine: false);

            line = <_PdfRichToken>[];
            lineWidth = 0;
          }

          line.add(token);
          lineWidth += tokenWidth;
        }

        if (line.isNotEmpty) {
          await drawLine(line, isLastLine: true);
        }

        y += 8;

        if (y > pageHeight - 20) {
          newPage();
        }
      }

      final bytes = await document.save();

      await File(outputPath).writeAsBytes(bytes, flush: true);
    } finally {
      document.dispose();
    }
  }

  /// Speichert ein PDF-Dokument.
  Future<void> save(PdfDocument document, String outputPath) async {
    final bytes = await document.save();

    final file = File(outputPath);

    await file.writeAsBytes(bytes);

    document.dispose();
  }
}

class _PdfRichRun {
  const _PdfRichRun({
    required this.text,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.fontFamily,
    required this.fontSize,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final String? fontFamily;
  final double fontSize;
}

class _PdfRichParagraph {
  const _PdfRichParagraph({required this.runs, required this.alignment});

  final List<_PdfRichRun> runs;
  final PdfTextAlignment alignment;
}

class _PdfRichToken {
  const _PdfRichToken({required this.text, required this.run});

  final String text;
  final _PdfRichRun run;
}

double _pdfFontSizeFromQuill(dynamic value) {
  if (value == null) {
    return 12;
  }

  if (value is num) {
    return value.toDouble();
  }

  final text = value.toString().toLowerCase();

  final numeric = double.tryParse(text);

  if (numeric != null && numeric > 0) {
    return numeric;
  }

  switch (text) {
    case 'small':
      return 9;
    case 'large':
      return 18;
    case 'huge':
      return 24;
    default:
      return 12;
  }
}

PdfTextAlignment _pdfAlignmentFromQuill(String? value) {
  switch (value) {
    case 'center':
      return PdfTextAlignment.center;
    case 'right':
      return PdfTextAlignment.right;
    case 'justify':
      return PdfTextAlignment.justify;
    default:
      return PdfTextAlignment.left;
  }
}

PdfFontFamily _pdfFontFamilyFromQuill(String? value) {
  final font = value?.toLowerCase() ?? '';

  if (font.contains('times') ||
      font.contains('serif') ||
      font.contains('georgia')) {
    return PdfFontFamily.timesRoman;
  }

  if (font.contains('courier') || font.contains('mono')) {
    return PdfFontFamily.courier;
  }

  return PdfFontFamily.helvetica;
}

PdfFont _pdfFontForRun(_PdfRichRun run) {
  final styles = <PdfFontStyle>[];

  if (run.bold) {
    styles.add(PdfFontStyle.bold);
  }

  if (run.italic) {
    styles.add(PdfFontStyle.italic);
  }

  if (run.underline) {
    styles.add(PdfFontStyle.underline);
  }

  return PdfStandardFont(
    _pdfFontFamilyFromQuill(run.fontFamily),
    run.fontSize,
    multiStyle: styles.isEmpty ? null : styles,
  );
}
