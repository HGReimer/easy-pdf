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

  /// Speichert ein PDF-Dokument.
  Future<void> save(
    PdfDocument document,
    String outputPath,
  ) async {
    final bytes = await document.save();

    final file = File(outputPath);

    await file.writeAsBytes(bytes);

    document.dispose();
  }
}