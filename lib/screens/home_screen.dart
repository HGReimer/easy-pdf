import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/pdf_service.dart';
import '../widgets/pdf_information.dart';
import '../widgets/pdf_toolbar.dart';
import '../widgets/pdf_view_panel.dart';

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

  void showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget buildStartView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.picture_as_pdf,
              size: 96,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Easy PDF',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Einfach. Schnell. Ohne Abo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
              ),
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
          child: PdfViewPanel(
            filePath: selectedFilePath!,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDocument = selectedFilePath != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Easy PDF'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          PdfToolbar(
            onOpen: pickPdf,
          ),
          Expanded(
            child: hasDocument
                ? buildDocumentView()
                : buildStartView(),
          ),
        ],
      ),
    );
  }
}