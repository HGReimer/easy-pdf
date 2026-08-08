import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/pdf_service.dart';
import '../widgets/pdf_information.dart';
import '../widgets/pdf_toolbar.dart';
import '../widgets/pdf_view_panel.dart';
import '../widgets/thumbnail_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PdfService pdfService = PdfService();

  String? selectedFileName;
  String? selectedFilePath;

  int pageCount = 0;
  int selectedPage = 1;

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) {
      return;
    }

    final file = result.files.single;
    final filePath = file.path;

    if (filePath == null) {
      showMessage('Die ausgewählte Datei konnte nicht geöffnet werden.');
      return;
    }

    try {
      final pages = pdfService.getPageCount(filePath);

      setState(() {
        selectedFileName = file.name;
        selectedFilePath = filePath;
        pageCount = pages;
        selectedPage = 1;
      });

      debugPrint('PDF: $selectedFileName');
      debugPrint('Seiten: $pageCount');
    } catch (error) {
      showMessage('PDF konnte nicht gelesen werden: $error');
    }
  }

  void selectPage(int page) {
    setState(() {
      selectedPage = page;
    });

    debugPrint('Ausgewählte Seite: $selectedPage');
  }

  void showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> confirmDeletePage() async {
    final inputPath = selectedFilePath;

    if (inputPath == null) {
      showMessage('Keine PDF-Datei geöffnet.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seite löschen'),
          content: Text('Seite $selectedPage wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final inputFile = File(inputPath);

      final dotIndex = inputPath.toLowerCase().lastIndexOf('.pdf');

      final outputPath = dotIndex >= 0
          ? '${inputPath.substring(0, dotIndex)}_bearbeitet.pdf'
          : '${inputPath}_bearbeitet.pdf';

      await inputFile.copy('$inputPath.backup');

      await pdfService.deletePage(
        inputPath: inputPath,
        outputPath: outputPath,
        pageNumber: selectedPage,
      );

      final newPageCount = pdfService.getPageCount(outputPath);

      setState(() {
        selectedFilePath = outputPath;
        selectedFileName = File(outputPath).uri.pathSegments.last;
        pageCount = newPageCount;

        if (selectedPage > newPageCount) {
          selectedPage = newPageCount;
        }
      });

      showMessage(
        'Seite gelöscht. Neue Datei: ${File(outputPath).uri.pathSegments.last}',
      );
    } catch (error) {
      showMessage('Seite konnte nicht gelöscht werden: $error');
    }
  }

  Widget buildStartView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 96, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Easy PDF',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Einfach. Schnell. Ohne Abo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: pickPdf,
              icon: const Icon(Icons.folder_open),
              label: const Text('PDF öffnen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDocumentView() {
    return Column(
      children: [
        PdfInformation(
          fileName: selectedFileName ?? 'Unbekannte Datei',
          pageCount: pageCount,
          selectedPage: selectedPage,
        ),
        Expanded(
          child: Row(
            children: [
              ThumbnailPanel(
                filePath: selectedFilePath!,
                selectedPage: selectedPage,
                onPageSelected: selectPage,
              ),
              Expanded(
                child: PdfViewPanel(
                  filePath: selectedFilePath!,
                  selectedPage: selectedPage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDocument = selectedFilePath != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Easy PDF'), centerTitle: true),
      body: Column(
        children: [
          PdfToolbar(
            onOpen: pickPdf,
            onDeletePage: selectedFilePath == null ? null : confirmDeletePage,
          ),
          Expanded(child: hasDocument ? buildDocumentView() : buildStartView()),
        ],
      ),
    );
  }
}
