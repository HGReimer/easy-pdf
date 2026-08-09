import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  /// Öffnet ein PDF-Dokument.
  PdfDocument open(String path) {
    final bytes = File(path).readAsBytesSync();
    return PdfDocument(inputBytes: bytes);
  }

  /// Gibt die Anzahl der Seiten zurück.
  int getPageCount(String path) {
    final document = open(path);

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

  /// Speichert ein PDF-Dokument.
  Future<void> save(PdfDocument document, String outputPath) async {
    final bytes = await document.save();

    final file = File(outputPath);

    await file.writeAsBytes(bytes);

    document.dispose();
  }
}
