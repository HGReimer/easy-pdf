import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
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
  bool mergeMode = false;
  final List<String> mergePdfPaths = [];

  int pageCount = 0;
  int selectedPage = 1;

  void startMergeMode() {
    setState(() {
      mergeMode = true;
      mergePdfPaths.clear();
      selectedFileName = null;
      selectedFilePath = null;
      pageCount = 0;
      selectedPage = 1;
    });

    showMessage("Merge-Modus aktiv – PDFs einzeln hineinziehen.");
  }

  Future<void> finishMergeMode() async {
    if (mergePdfPaths.length < 2) {
      showMessage("Bitte mindestens zwei PDFs sammeln.");
      return;
    }

    try {
      final firstPath = mergePdfPaths.first;
      final dotIndex = firstPath.toLowerCase().lastIndexOf(".pdf");
      final outputPath = dotIndex >= 0
          ? "${firstPath.substring(0, dotIndex)}_zusammengefuegt.pdf"
          : "${firstPath}_zusammengefuegt.pdf";

      await pdfService.mergePdfs(
        inputPaths: List<String>.from(mergePdfPaths),
        outputPath: outputPath,
      );

      final pages = pdfService.getPageCount(outputPath);

      setState(() {
        mergeMode = false;
        mergePdfPaths.clear();
        selectedFilePath = outputPath;
        selectedFileName = File(outputPath).uri.pathSegments.last;
        pageCount = pages;
        selectedPage = 1;
      });

      showMessage("PDFs erfolgreich zusammengeführt.");
    } catch (error) {
      showMessage("PDFs konnten nicht zusammengeführt werden: $error");
    }
  }

  Future<void> pickPdf() async {
    const pdfTypeGroup = XTypeGroup(label: 'PDF', extensions: ['pdf']);

    final file = await openFile(acceptedTypeGroups: [pdfTypeGroup]);

    if (file == null) {
      return;
    }

    final filePath = file.path;

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
      if (error.toString().toLowerCase().contains('passwortgeschützt')) {
        showMessage(
          'Diese PDF ist passwortgeschützt und kann derzeit nicht geöffnet werden.',
        );
      } else {
        showMessage('PDF konnte nicht gelesen werden: $error');
      }
    }
  }

  Future<void> pickPdfsAndMerge() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result == null) {
      return;
    }

    final inputPaths = result.files
        .where((file) => file.path != null)
        .map((file) => file.path!)
        .toList();

    if (inputPaths.length < 2) {
      showMessage('Bitte mindestens zwei PDF-Dateien auswählen.');
      return;
    }

    try {
      final firstPath = inputPaths.first;
      final dotIndex = firstPath.toLowerCase().lastIndexOf('.pdf');

      final outputPath = dotIndex >= 0
          ? '${firstPath.substring(0, dotIndex)}_zusammengefuegt.pdf'
          : '${firstPath}_zusammengefuegt.pdf';

      await pdfService.mergePdfs(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      final pages = pdfService.getPageCount(outputPath);

      setState(() {
        selectedFilePath = outputPath;
        selectedFileName = File(outputPath).uri.pathSegments.last;
        pageCount = pages;
        selectedPage = 1;
      });

      showMessage(
        '${inputPaths.length} PDFs zusammengeführt. '
        'Neue Datei: ${File(outputPath).uri.pathSegments.last}',
      );
    } catch (error) {
      showMessage('PDFs konnten nicht zusammengeführt werden: $error');
    }
  }

  void closeCurrentPdf() {
    if (selectedFilePath == null) {
      return;
    }

    setState(() {
      selectedFileName = null;
      selectedFilePath = null;
      pageCount = 0;
      selectedPage = 1;
    });

    showMessage('PDF geschlossen.');
  }

  void selectPage(int page) {
    setState(() {
      selectedPage = page;
    });

    debugPrint('Ausgewählte Seite: $selectedPage');
  }

  void goToPreviousPage() {
    if (selectedPage > 1) {
      selectPage(selectedPage - 1);
    }
  }

  void goToNextPage() {
    if (selectedPage < pageCount) {
      selectPage(selectedPage + 1);
    }
  }

  void showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> extractCurrentPage() async {
    final inputPath = selectedFilePath;

    if (inputPath == null) {
      showMessage('Keine PDF-Datei geöffnet.');
      return;
    }

    try {
      final dotIndex = inputPath.toLowerCase().lastIndexOf('.pdf');

      final outputPath = dotIndex >= 0
          ? '${inputPath.substring(0, dotIndex)}_seite_$selectedPage.pdf'
          : '${inputPath}_seite_$selectedPage.pdf';

      await pdfService.extractPage(
        inputPath: inputPath,
        outputPath: outputPath,
        pageNumber: selectedPage,
      );

      showMessage('Seite $selectedPage wurde extrahiert.');
    } catch (error) {
      showMessage('Seite konnte nicht extrahiert werden: $error');
    }
  }

  Future<void> reorderCurrentPages(List<int> pageOrder) async {
    final inputPath = selectedFilePath;

    if (inputPath == null) {
      showMessage('Keine PDF-Datei geöffnet.');
      return;
    }

    try {
      final dotIndex = inputPath.toLowerCase().lastIndexOf('.pdf');

      final outputPath = dotIndex >= 0
          ? '${inputPath.substring(0, dotIndex)}_sortiert.pdf'
          : '${inputPath}_sortiert.pdf';

      await File(inputPath).copy('$inputPath.backup');

      final newSelectedPage = pageOrder.indexOf(selectedPage) + 1;

      await pdfService.reorderPages(
        inputPath: inputPath,
        outputPath: outputPath,
        pageOrder: pageOrder,
      );

      setState(() {
        selectedFilePath = outputPath;
        selectedFileName = File(outputPath).uri.pathSegments.last;
        pageCount = pageOrder.length;
        selectedPage = newSelectedPage > 0 ? newSelectedPage : 1;
      });

      showMessage(
        'Seiten neu sortiert. Neue Datei: ${File(outputPath).uri.pathSegments.last}',
      );
    } catch (error) {
      showMessage('Seiten konnten nicht neu sortiert werden: $error');
    }
  }

  Future<void> rotateCurrentPage() async {
    final inputPath = selectedFilePath;

    if (inputPath == null) {
      showMessage('Keine PDF-Datei geöffnet.');
      return;
    }

    try {
      final dotIndex = inputPath.toLowerCase().lastIndexOf('.pdf');

      final outputPath = dotIndex >= 0
          ? '${inputPath.substring(0, dotIndex)}_gedreht.pdf'
          : '${inputPath}_gedreht.pdf';

      await File(inputPath).copy('$inputPath.backup');

      await pdfService.rotatePage(
        inputPath: inputPath,
        outputPath: outputPath,
        pageNumber: selectedPage,
      );

      setState(() {
        selectedFilePath = outputPath;
        selectedFileName = File(outputPath).uri.pathSegments.last;
      });

      showMessage('Seite $selectedPage wurde um 90° gedreht.');
    } catch (error) {
      showMessage('Seite konnte nicht gedreht werden: $error');
    }
  }

  Future<void> pickImageAndCreatePdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result == null) {
      return;
    }

    final file = result.files.single;
    final imagePath = file.path;

    if (imagePath == null) {
      showMessage('Das ausgewählte Bild konnte nicht geöffnet werden.');
      return;
    }

    final baseName = file.name.contains('.')
        ? file.name.substring(0, file.name.lastIndexOf('.'))
        : file.name;

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Bild als PDF speichern',
      fileName: '$baseName.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputPath == null) {
      return;
    }

    final pdfPath = outputPath.toLowerCase().endsWith('.pdf')
        ? outputPath
        : '$outputPath.pdf';

    try {
      await pdfService.createPdfFromImage(
        imagePath: imagePath,
        outputPath: pdfPath,
      );

      final pages = pdfService.getPageCount(pdfPath);

      setState(() {
        selectedFileName = File(pdfPath).uri.pathSegments.last;
        selectedFilePath = pdfPath;
        pageCount = pages;
        selectedPage = 1;
      });

      showMessage('Bild wurde erfolgreich in PDF umgewandelt.');
    } catch (error) {
      showMessage('Bild konnte nicht in PDF umgewandelt werden: $error');
    }
  }

  Future<void> saveCurrentPdf() async {
    final inputPath = selectedFilePath;

    if (inputPath == null) {
      showMessage('Keine PDF-Datei geöffnet.');
      return;
    }

    final saveLocation = await getSaveLocation(
      suggestedName: selectedFileName ?? 'dokument.pdf',
    );

    if (saveLocation == null) {
      return;
    }

    final outputPath = saveLocation.path;

    final pdfPath = outputPath.toLowerCase().endsWith('.pdf')
        ? outputPath
        : '$outputPath.pdf';

    try {
      if (File(inputPath).absolute.path == File(pdfPath).absolute.path) {
        showMessage('Die PDF ist bereits unter diesem Namen gespeichert.');
        return;
      }

      await File(inputPath).copy(pdfPath);

      setState(() {
        selectedFilePath = pdfPath;
        selectedFileName = File(pdfPath).uri.pathSegments.last;
      });

      showMessage('PDF gespeichert: ${File(pdfPath).uri.pathSegments.last}');
    } catch (error) {
      showMessage('PDF konnte nicht gespeichert werden: $error');
    }
  }

  Future<void> confirmDeletePage([int? pageNumber]) async {
    final pageToDelete = pageNumber ?? selectedPage;
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
          content: Text('Seite $pageToDelete wirklich löschen?'),
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
        pageNumber: pageToDelete,
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: pickPdf,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('PDF öffnen'),
                ),
                if (mergeMode)
                  FilledButton.icon(
                    onPressed: mergePdfPaths.length < 2
                        ? null
                        : finishMergeMode,
                    icon: const Icon(Icons.merge),
                    label: Text(
                      "Jetzt zusammenführen (${mergePdfPaths.length})",
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: startMergeMode,
                    icon: const Icon(Icons.merge_type),
                    label: const Text("PDFs zusammenführen"),
                  ),
              ],
            ),
            if (mergeMode) ...[
              const SizedBox(height: 24),
              const Text(
                "Sammelkorb",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (mergePdfPaths.isEmpty)
                const Text("Noch keine PDFs gesammelt.")
              else
                ...mergePdfPaths.map(
                  (path) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(File(path).uri.pathSegments.last),
                      IconButton(
                        onPressed: () =>
                            setState(() => mergePdfPaths.remove(path)),
                        icon: const Icon(Icons.close),
                        tooltip: "Aus Sammelkorb entfernen",
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    mergeMode = false;
                    mergePdfPaths.clear();
                  });
                  showMessage("Merge abgebrochen.");
                },
                icon: const Icon(Icons.cancel),
                label: const Text("Merge abbrechen"),
              ),
            ],
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
                onPageReordered: reorderCurrentPages,
                onPageDelete: confirmDeletePage,
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
      body: DropTarget(
        onDragDone: (detail) async {
          if (detail.files.isEmpty) {
            return;
          }

            final imagePaths = detail.files
                .map((file) => file.path)
                .where((path) {
                  final p = path.toLowerCase();
                  return p.endsWith('.jpg') ||
                      p.endsWith('.jpeg') ||
                      p.endsWith('.png');
                })
                .toList();

            if (imagePaths.length > 1) {
              final outputPath = await FilePicker.platform.saveFile(
                dialogTitle: 'Bilder als PDF speichern',
                fileName: 'bilder.pdf',
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );

              if (outputPath == null) {
                return;
              }

              final pdfPath = outputPath.toLowerCase().endsWith('.pdf')
                  ? outputPath
                  : '$outputPath.pdf';

              try {
                await pdfService.createPdfFromImages(
                  imagePaths: imagePaths,
                  outputPath: pdfPath,
                );

                final pages = pdfService.getPageCount(pdfPath);

                setState(() {
                  selectedFileName = File(pdfPath).uri.pathSegments.last;
                  selectedFilePath = pdfPath;
                  pageCount = pages;
                  selectedPage = 1;
                });

                showMessage(
                  '${imagePaths.length} Bilder erfolgreich in PDF umgewandelt.',
                );
              } catch (error) {
                showMessage(
                  'Bilder konnten nicht umgewandelt werden: $error',
                );
              }

              return;
            }
          final droppedFile = detail.files.first;
          final droppedPath = droppedFile.path;
          final lowerPath = droppedPath.toLowerCase();

          if (mergeMode && lowerPath.endsWith(".pdf")) {
            setState(() {
              if (!mergePdfPaths.contains(droppedPath)) {
                mergePdfPaths.add(droppedPath);
              }
            });

            showMessage("${mergePdfPaths.length} PDF(s) im Sammelkorb.");
            return;
          }

          if (lowerPath.endsWith('.pdf')) {
            try {
              final pages = pdfService.getPageCount(droppedPath);

              setState(() {
                selectedFileName = File(droppedPath).uri.pathSegments.last;
                selectedFilePath = droppedPath;
                pageCount = pages;
                selectedPage = 1;
              });

              showMessage('PDF per Drag & Drop geöffnet.');
            } catch (error) {
              showMessage('PDF konnte nicht geöffnet werden: $error');
            }
            return;
          }

          final isImage =
              lowerPath.endsWith('.jpg') ||
              lowerPath.endsWith('.jpeg') ||
              lowerPath.endsWith('.png');

          if (isImage) {
            final imageName = File(droppedPath).uri.pathSegments.last;
            final dotIndex = imageName.lastIndexOf('.');
            final baseName = dotIndex > 0
                ? imageName.substring(0, dotIndex)
                : imageName;

            final outputPath = await FilePicker.platform.saveFile(
              dialogTitle: 'Bild als PDF speichern',
              fileName: '$baseName.pdf',
              type: FileType.custom,
              allowedExtensions: ['pdf'],
            );

            if (outputPath == null) {
              return;
            }

            final pdfPath = outputPath.toLowerCase().endsWith('.pdf')
                ? outputPath
                : '$outputPath.pdf';

            try {
              await pdfService.createPdfFromImage(
                imagePath: droppedPath,
                outputPath: pdfPath,
              );

              final pages = pdfService.getPageCount(pdfPath);

              setState(() {
                selectedFileName = File(pdfPath).uri.pathSegments.last;
                selectedFilePath = pdfPath;
                pageCount = pages;
                selectedPage = 1;
              });

              showMessage('Bild per Drag & Drop in PDF umgewandelt.');
            } catch (error) {
              showMessage('Bild konnte nicht umgewandelt werden: $error');
            }
            return;
          }

          showMessage('Dateityp wird noch nicht unterstützt.');
        },
        child: Column(
          children: [
            PdfToolbar(
              onOpen: pickPdf,
              onImageToPdf: pickImageAndCreatePdf,
              onSave: selectedFilePath == null ? null : saveCurrentPdf,
              onClose: selectedFilePath == null ? null : closeCurrentPdf,
              onDeletePage: selectedFilePath == null ? null : confirmDeletePage,
              onRotatePage: selectedFilePath == null ? null : rotateCurrentPage,
              onExtractPage: selectedFilePath == null
                  ? null
                  : extractCurrentPage,
              onPreviousPage: selectedFilePath == null || selectedPage <= 1
                  ? null
                  : goToPreviousPage,
              onNextPage: selectedFilePath == null || selectedPage >= pageCount
                  ? null
                  : goToNextPage,
              selectedPage: selectedPage,
              pageCount: pageCount,
            ),
            Expanded(
              child: hasDocument ? buildDocumentView() : buildStartView(),
            ),
          ],
        ),
      ),
    );
  }
}
