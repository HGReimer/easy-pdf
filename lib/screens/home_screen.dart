import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../services/pdf_service.dart';
import '../widgets/pdf_toolbar.dart';

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

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) {
      return;
    }

    final file = result.files.single;

    if (file.path == null) {
      return;
    }

    final filePath = file.path!;
    final pages = pdfService.getPageCount(filePath);

    setState(() {
      selectedFileName = file.name;
      selectedFilePath = filePath;
      pageCount = pages;
    });

    debugPrint('PDF: $selectedFileName');
    debugPrint('Seiten: $pageCount');
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

  Widget buildPdfView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          color: Colors.grey.shade200,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '📄 ${selectedFileName ?? '-'}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '📑 $pageCount Seiten',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SfPdfViewer.file(
            File(selectedFilePath!),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: selectedFilePath == null
                ? buildStartView()
                : buildPdfView(),
          ),
        ],
      ),
    );
  }
}