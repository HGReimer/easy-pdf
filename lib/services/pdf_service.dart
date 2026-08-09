import 'dart:io';

import 'package:flutter/material.dart';

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

  /// Speichert ein PDF-Dokument.
  Future<void> save(PdfDocument document, String outputPath) async {
    final bytes = await document.save();

    final file = File(outputPath);

    await file.writeAsBytes(bytes);

    document.dispose();
  }
}
