import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../services/pdf_service.dart';
import 'drawing_canvas_screen.dart';
import 'text_pdf_screen.dart';
import '../services/purchase_service.dart';
import '../widgets/pdf_information.dart';
import '../widgets/pdf_toolbar.dart';
import '../widgets/pdf_view_panel.dart';
import '../widgets/thumbnail_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialFilePath});

  final String? initialFilePath;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PdfService pdfService = PdfService();
  final PurchaseService _purchaseService = PurchaseService();

  static const MethodChannel _printChannel = MethodChannel(
    "de.easyschmiede.easypdf/print",
  );

  String? selectedFileName;
  String? selectedFilePath;
  Uint8List? selectedFileBytes;
  bool mergeMode = false;
  final List<String> mergePdfPaths = [];

  int pageCount = 0;
  int selectedPage = 1;
  @override
  void initState() {
    super.initState();

    _purchaseService.addListener(_handlePurchaseServiceChanged);
    _purchaseService.initialize();

    final initialFilePath = widget.initialFilePath;
    if (initialFilePath != null && initialFilePath.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openPdfPath(initialFilePath);
      });
    }
  }

  void _handlePurchaseServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _purchaseService.removeListener(_handlePurchaseServiceChanged);
    _purchaseService.dispose();
    super.dispose();
  }

  Future<void> openPdfPath(String filePath) async {
    try {
      final pages = pdfService.getPageCount(filePath);

      setState(() {
        selectedFileName = File(filePath).uri.pathSegments.last;
        selectedFilePath = filePath;
        selectedFileBytes = null;
        pageCount = pages;
        selectedPage = 1;
      });

      debugPrint("PDF: $selectedFileName");
      debugPrint("Seiten: $pageCount");
    } catch (error) {
      if (error.toString().toLowerCase().contains("passwortgeschützt")) {
        showMessage(
          "Diese PDF ist passwortgeschützt und kann derzeit nicht geöffnet werden.",
        );
      } else {
        showMessage("PDF konnte nicht gelesen werden: $error");
      }
    }
  }

  void startMergeMode() {
    if (!_purchaseService.isProUnlocked) {
      showProDialog();
      return;
    }

    setState(() {
      mergeMode = true;
      mergePdfPaths.clear();
      selectedFileName = null;
      selectedFilePath = null;
      selectedFileBytes = null;
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
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        lockParentWindow: true,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.first;

      if (kIsWeb) {
        final bytes = pickedFile.bytes;

        if (bytes == null) {
          showMessage('Die ausgewählte PDF-Datei konnte nicht gelesen werden.');
          return;
        }

        final pages = pdfService.getPageCountFromBytes(bytes);

        setState(() {
          selectedFileName = pickedFile.name;
          selectedFilePath = pickedFile.name;
          selectedFileBytes = bytes;
          pageCount = pages;
          selectedPage = 1;
        });

        return;
      }

      final path = pickedFile.path;

      if (path == null) {
        showMessage('Die ausgewählte PDF-Datei konnte nicht geöffnet werden.');
        return;
      }

      await openPdfPath(path);
    } catch (error) {
      showMessage('PDF-Datei konnte nicht geöffnet werden: $error');
    }
  }

  Future<void> pickPdfsAndMerge() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      lockParentWindow: true,
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

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: "Extrahierte Seite speichern unter",
      fileName: "seite_$selectedPage.pdf",
      type: FileType.custom,
      allowedExtensions: ["pdf"],
      lockParentWindow: true,
    );

    if (savePath == null) {
      return;
    }

    final outputPath = savePath.toLowerCase().endsWith(".pdf")
        ? savePath
        : "$savePath.pdf";

    try {
      await pdfService.extractPage(
        inputPath: inputPath,
        outputPath: outputPath,
        pageNumber: selectedPage,
      );

      showMessage("Seite $selectedPage wurde gespeichert.");
    } catch (error) {
      showMessage('Seite konnte nicht extrahiert werden: $error');
    }
  }

  Future<void> exportCurrentPageAsPng() async {
    final inputPath = selectedFilePath;

    if (inputPath == null) {
      showMessage("Keine PDF-Datei geöffnet.");
      return;
    }

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: "PDF-Seite als Bild speichern",
      fileName: "seite_$selectedPage.png",
      type: FileType.custom,
      allowedExtensions: ["png"],
      lockParentWindow: true,
    );

    if (outputPath == null) {
      return;
    }

    final pngPath = outputPath.toLowerCase().endsWith(".png")
        ? outputPath
        : "$outputPath.png";

    try {
      await pdfService.exportPageAsPng(
        inputPath: inputPath,
        outputPath: pngPath,
        pageNumber: selectedPage,
      );

      showMessage("Seite $selectedPage wurde als PNG gespeichert.");
    } catch (error) {
      showMessage("Seite konnte nicht als Bild gespeichert werden: $error");
    }
  }

  Future<void> exportPageRangeAsPng() async {
    final inputPath = selectedFilePath;

    if (inputPath == null) {
      showMessage('Keine PDF-Datei geöffnet.');
      return;
    }

    final startController = TextEditingController(text: '1');
    final endController = TextEditingController(text: pageCount.toString());

    final range = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seiten als Bilder speichern'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Seitenbereich 1 bis $pageCount auswählen'),
              const SizedBox(height: 16),
              TextField(
                controller: startController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Von Seite'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Bis Seite'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                final startPage = int.tryParse(startController.text);
                final endPage = int.tryParse(endController.text);

                if (startPage == null ||
                    endPage == null ||
                    startPage < 1 ||
                    endPage > pageCount ||
                    startPage > endPage) {
                  return;
                }

                Navigator.pop(context, [startPage, endPage]);
              },
              child: const Text('Exportieren'),
            ),
          ],
        );
      },
    );

    startController.dispose();
    endController.dispose();

    if (range == null) {
      return;
    }

    final startPage = range[0];
    final endPage = range[1];

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: "PNG-Bilder speichern unter",
      fileName: "seiten_${startPage}_bis_$endPage.png",
      type: FileType.custom,
      lockParentWindow: true,
      allowedExtensions: ["png"],
    );

    if (savePath == null) {
      return;
    }

    final normalizedPath = savePath.toLowerCase().endsWith(".png")
        ? savePath.substring(0, savePath.length - 4)
        : savePath;

    try {
      for (var pageNumber = startPage; pageNumber <= endPage; pageNumber++) {
        final outputPath = "${normalizedPath}_Seite_$pageNumber.png";

        await pdfService.exportPageAsPng(
          inputPath: inputPath,
          outputPath: outputPath,
          pageNumber: pageNumber,
        );
      }

      showMessage(
        '${endPage - startPage + 1} Seite(n) wurden als PNG gespeichert.',
      );
    } catch (error) {
      showMessage('Seiten konnten nicht als Bilder gespeichert werden: $error');
    }
  }

  Future<void> splitPdfByPageRange() async {
    final inputPath = selectedFilePath;

    if (inputPath == null) {
      showMessage('Keine PDF-Datei geöffnet.');
      return;
    }

    final startController = TextEditingController(
      text: selectedPage.toString(),
    );
    final endController = TextEditingController(text: pageCount.toString());

    final range = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('PDF teilen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Seitenbereich 1 bis $pageCount auswählen'),
              const SizedBox(height: 16),
              TextField(
                controller: startController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Von Seite'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Bis Seite'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                final startPage = int.tryParse(startController.text);
                final endPage = int.tryParse(endController.text);

                if (startPage == null ||
                    endPage == null ||
                    startPage < 1 ||
                    endPage > pageCount ||
                    startPage > endPage) {
                  return;
                }

                Navigator.pop(context, [startPage, endPage]);
              },
              child: const Text('Teilen'),
            ),
          ],
        );
      },
    );

    startController.dispose();
    endController.dispose();

    if (range == null) {
      return;
    }

    final startPage = range[0];
    final endPage = range[1];

    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: "Geteilte PDF speichern",
        fileName: "seiten_${startPage}_bis_$endPage.pdf",
        lockParentWindow: true,
        type: FileType.custom,
        allowedExtensions: ["pdf"],
      );

      if (outputPath == null) {
        return;
      }

      final pdfPath = outputPath.toLowerCase().endsWith(".pdf")
          ? outputPath
          : "$outputPath.pdf";

      await pdfService.extractPageRange(
        inputPath: inputPath,
        outputPath: pdfPath,
        startPage: startPage,
        endPage: endPage,
      );

      showMessage(
        'Seiten $startPage bis $endPage wurden als neue PDF gespeichert.',
      );
    } catch (error) {
      showMessage('PDF konnte nicht geteilt werden: $error');
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

  Future<void> createPdfFromText() async {
    final result = await Navigator.of(context).push<TextPdfResult>(
      MaterialPageRoute(builder: (context) => const TextPdfScreen()),
    );

    if (result == null) {
      return;
    }

    try {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'easy_pdf_text_',
      );

      final pdfPath =
          '${tempDirectory.path}${Platform.pathSeparator}textdokument.pdf';

      await pdfService.createPdfFromText(
        outputPath: pdfPath,
        title: result.title,
        deltaJson: result.deltaJson,
      );

      final pages = pdfService.getPageCount(pdfPath);

      setState(() {
        selectedFileName = result.title.trim().isEmpty
            ? 'textdokument.pdf'
            : '${result.title.trim().replaceAll(' ', '_')}.pdf';
        selectedFilePath = pdfPath;
        selectedFileBytes = null;
        pageCount = pages;
        selectedPage = 1;
      });

      showMessage('PDF aus Text erstellt. Zum Behalten bitte speichern.');
    } catch (error) {
      showMessage('PDF aus Text konnte nicht erstellt werden: $error');
    }
  }

  Future<void> createPdfFromDrawing() async {
    final drawingBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (context) => const DrawingCanvasScreen()),
    );

    if (drawingBytes == null || drawingBytes.isEmpty) {
      return;
    }

    try {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'easy_pdf_drawing_',
      );

      final imagePath =
          '${tempDirectory.path}${Platform.pathSeparator}zeichnung.png';

      final pdfPath =
          '${tempDirectory.path}${Platform.pathSeparator}zeichnung.pdf';

      await File(imagePath).writeAsBytes(drawingBytes, flush: true);

      await pdfService.createPdfFromImage(
        imagePath: imagePath,
        outputPath: pdfPath,
      );

      final pages = pdfService.getPageCount(pdfPath);

      setState(() {
        selectedFileName = 'zeichnung.pdf';
        selectedFilePath = pdfPath;
        selectedFileBytes = null;
        pageCount = pages;
        selectedPage = 1;
      });

      showMessage('PDF aus Zeichnung erstellt. Zum Behalten bitte speichern.');
    } catch (error) {
      showMessage('PDF aus Zeichnung konnte nicht erstellt werden: $error');
    }
  }

  Future<void> pickImageAndCreatePdf() async {
    if (!_purchaseService.isProUnlocked) {
      await showProDialog();
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: true,
        lockParentWindow: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final imagePaths = result.files
          .where((file) => file.path != null)
          .map((file) => file.path!)
          .toList();

      if (imagePaths.isEmpty) {
        showMessage("Die ausgewählten Bilder konnten nicht geöffnet werden.");
        return;
      }

      final rawBaseName = file.name.contains('.')
          ? file.name.substring(0, file.name.lastIndexOf('.'))
          : file.name;
      final singleBaseName = rawBaseName.trim().isEmpty ? "bild" : rawBaseName;
      final baseName = imagePaths.length > 1 ? "bilder" : singleBaseName;

      final tempDirectory = await Directory.systemTemp.createTemp('easy_pdf_');
      final pdfPath =
          '${tempDirectory.path}${Platform.pathSeparator}$baseName.pdf';

      await pdfService.createPdfFromImages(
        imagePaths: imagePaths,
        outputPath: pdfPath,
      );

      final pages = pdfService.getPageCount(pdfPath);

      setState(() {
        selectedFileName = '$baseName.pdf';
        selectedFilePath = pdfPath;
        pageCount = pages;
        selectedPage = 1;
      });

      showMessage(
        imagePaths.length == 1
            ? "Bild erfolgreich in PDF umgewandelt. Zum Behalten bitte speichern."
            : "${imagePaths.length} Bilder erfolgreich in eine PDF umgewandelt. Zum Behalten bitte speichern.",
      );
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

    final suggestedName = selectedFileName ?? 'dokument.pdf';
    final initialName = suggestedName.toLowerCase().endsWith('.pdf')
        ? suggestedName.substring(0, suggestedName.length - 4)
        : suggestedName;

    final nameController = TextEditingController(text: initialName);
    nameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: initialName.length,
    );

    final enteredName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('PDF speichern'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Dateiname',
              suffixText: '.pdf',
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop(value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                final value = nameController.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              child: const Text('Weiter'),
            ),
          ],
        );
      },
    );

    nameController.dispose();

    if (enteredName == null) {
      return;
    }

    var baseName = enteredName.trim();

    if (baseName.toLowerCase().endsWith('.pdf')) {
      baseName = baseName.substring(0, baseName.length - 4);
    }

    baseName = baseName.replaceAll('/', '_').replaceAll(':', '_');

    if (baseName.isEmpty) {
      showMessage('Bitte einen Dateinamen eingeben.');
      return;
    }

    final pdfName = '$baseName.pdf';

    try {
      final bytes = await File(inputPath).readAsBytes();

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'PDF speichern',
        lockParentWindow: true,
        fileName: pdfName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );

      if (outputPath == null) {
        return;
      }

      if (!Platform.isAndroid && !Platform.isIOS) {
        final desktopPath = outputPath.toLowerCase().endsWith('.pdf')
            ? outputPath
            : '$outputPath.pdf';

        await File(desktopPath).writeAsBytes(bytes, flush: true);

        setState(() {
          selectedFilePath = desktopPath;
          selectedFileName = File(desktopPath).uri.pathSegments.last;
        });
      } else {
        setState(() {
          selectedFileName = pdfName;
        });
      }

      showMessage('PDF „$pdfName“ wurde erfolgreich gespeichert.');
    } catch (error) {
      showMessage('PDF konnte nicht gespeichert werden: $error');
    }
  }

  Future<void> printCurrentPdf() async {
    final inputPath = selectedFilePath;

    if (inputPath == null) {
      showMessage("Keine PDF-Datei geöffnet.");
      return;
    }

    if (Platform.isIOS) {
      try {
        final bytes = await File(inputPath).readAsBytes();
        final printed = await _printChannel.invokeMethod<bool>("printPdf", {
          "bytes": bytes,
          "name": selectedFileName ?? "Easy PDF.pdf",
        });

        if (!mounted) {
          return;
        }

        showMessage(
          printed == true
              ? "Der Druckauftrag wurde übergeben."
              : "Der Druckvorgang wurde abgebrochen.",
        );
      } catch (error) {
        showMessage("PDF konnte nicht gedruckt werden: $error");
      }
      return;
    }

    if (!Platform.isLinux) {
      showMessage("Drucken wird auf diesem System noch nicht unterstützt.");
      return;
    }

    try {
      final status = await Process.run("lpstat", ["-a"]);
      final printers =
          status.stdout
              .toString()
              .split("\n")
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .map((line) => line.split(RegExp(r"\s+")).first)
              .toSet()
              .toList()
            ..sort();

      if (printers.isEmpty) {
        showMessage(
          "Es wurde noch kein Drucker eingerichtet. Bitte zuerst in Linux einen Drucker hinzufügen.",
        );
        return;
      }

      if (!mounted) {
        return;
      }

      final printer = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return SimpleDialog(
            title: const Text("Drucker auswählen"),
            children: printers
                .map(
                  (printer) => SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(printer);
                    },
                    child: Text(printer),
                  ),
                )
                .toList(),
          );
        },
      );

      if (printer == null) {
        return;
      }

      final result = await Process.run("lp", ["-d", printer, inputPath]);

      if (result.exitCode == 0) {
        showMessage("Der Druckauftrag wurde an „$printer“ übergeben.");
      } else {
        showMessage("Der Druckauftrag konnte nicht übergeben werden.");
      }
    } catch (error) {
      showMessage("PDF konnte nicht gedruckt werden: $error");
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
                FilledButton.icon(
                  onPressed: () async {
                    if (!_purchaseService.isProUnlocked) {
                      await showProDialog();
                      return;
                    }

                    if (!mounted) return;

                    final choice = await showModalBottomSheet<String>(
                      context: context,
                      builder: (context) {
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.text_fields),
                                  title: const Text('PDF aus Text'),
                                  subtitle: const Text(
                                    'Titel und Text eingeben',
                                  ),
                                  onTap: () => Navigator.pop(context, 'text'),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.draw_outlined),
                                  title: const Text('PDF aus Zeichnung'),
                                  subtitle: const Text(
                                    'Freihand zeichnen und als PDF speichern',
                                  ),
                                  onTap: () =>
                                      Navigator.pop(context, 'drawing'),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.image_outlined),
                                  title: const Text('PDF aus Bildern'),
                                  subtitle: const Text(
                                    'Ein oder mehrere Bilder umwandeln',
                                  ),
                                  onTap: () => Navigator.pop(context, 'images'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    if (!mounted || choice == null) return;

                    switch (choice) {
                      case 'text':
                        await createPdfFromText();
                        break;
                      case 'drawing':
                        await createPdfFromDrawing();
                        break;
                      case 'images':
                        await pickImageAndCreatePdf();
                        break;
                    }
                  },
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('PDF erstellen'),
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
    final viewer = PdfViewPanel(
      key: ValueKey(selectedFileBytes ?? selectedFilePath),
      filePath: selectedFilePath!,
      fileBytes: selectedFileBytes,
      selectedPage: selectedPage,
    );

    return Column(
      children: [
        PdfInformation(
          fileName: selectedFileName ?? 'Unbekannte Datei',
          pageCount: pageCount,
          selectedPage: selectedPage,
        ),
        Expanded(
          child: kIsWeb
              ? viewer
              : Row(
                  children: [
                    ThumbnailPanel(
                      filePath: selectedFilePath!,
                      selectedPage: selectedPage,
                      onPageSelected: selectPage,
                      onPageReordered: (pageOrder) =>
                          _runProAction(() => reorderCurrentPages(pageOrder)),
                      onPageDelete: (pageNumber) =>
                          _runProAction(() => confirmDeletePage(pageNumber)),
                    ),
                    Expanded(child: viewer),
                  ],
                ),
        ),
      ],
    );
  }

  void _runProAction(VoidCallback action) {
    if (_purchaseService.isProUnlocked) {
      action();
    } else {
      showProDialog();
    }
  }

  Future<void> showProDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AnimatedBuilder(
          animation: _purchaseService,
          builder: (context, child) {
            final isPro = _purchaseService.isProUnlocked;
            final pending = _purchaseService.purchasePending;
            final price = _purchaseService.proPrice;
            final error = _purchaseService.errorMessage;

            if (isPro) {
              return AlertDialog(
                title: const Text('Easy PDF Pro'),
                content: const Text(
                  'Easy PDF Pro ist aktiv. Alle Funktionen stehen zur Verfügung.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Schließen'),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: const Text('Easy PDF Pro'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PDF-Dateien kannst du kostenlos öffnen, anzeigen '
                    'und durchsuchen.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pro schaltet Speichern, Drucken, Bild-zu-PDF, '
                    'Löschen, Drehen, Extrahieren, Bildexport und '
                    'PDF-Teilung frei.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Einmaliger Kauf – kein Abonnement.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (_purchaseService.isLoading) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Schließen'),
                ),
                TextButton(
                  onPressed: _purchaseService.storeAvailable && !pending
                      ? _purchaseService.restorePurchases
                      : null,
                  child: const Text('Käufe wiederherstellen'),
                ),
                FilledButton.icon(
                  onPressed:
                      _purchaseService.storeAvailable &&
                          price != null &&
                          !pending
                      ? _purchaseService.buyPro
                      : null,
                  icon: const Icon(Icons.workspace_premium),
                  label: Text(
                    pending
                        ? 'Bitte warten …'
                        : price == null
                        ? 'Pro kaufen'
                        : 'Pro kaufen – $price',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showAboutEasyPdf() {
    showAboutDialog(
      context: context,
      applicationName: 'Easy PDF',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Hans-Georg Reimer / EasySchmiede',
      children: [
        const SizedBox(height: 12),
        const Text('PDF-Dateien einfach öffnen, bearbeiten und organisieren.'),
        const SizedBox(height: 8),
        const Text('EasySchmiede – Software einfach gemacht.'),
        const SizedBox(height: 8),
        const Text(
          'Verwendete Komponenten unterliegen ihren jeweiligen Lizenzbedingungen.',
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () async {
            final opened = await launchUrl(
              Uri.parse(
                'https://hgreimer.github.io/easyschmiede/datenschutz-easy-pdf.html',
              ),
              mode: LaunchMode.externalApplication,
            );

            if (!opened && mounted) {
              showMessage('Die Datenschutzseite konnte nicht geöffnet werden.');
            }
          },
          icon: const Icon(Icons.privacy_tip_outlined),
          label: const Text('Datenschutzerklärung'),
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
        actions: [
          IconButton(
            onPressed: showProDialog,
            icon: Icon(
              _purchaseService.isProUnlocked
                  ? Icons.workspace_premium
                  : Icons.lock_outline,
            ),
            tooltip: _purchaseService.isProUnlocked
                ? 'Easy PDF Pro ist aktiv'
                : 'Easy PDF Pro freischalten',
          ),
          IconButton(
            onPressed: showAboutEasyPdf,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Über Easy PDF',
          ),
        ],
      ),
      body: DropTarget(
        onDragDone: (detail) async {
          if (detail.files.isEmpty) {
            return;
          }

          final imagePaths = detail.files.map((file) => file.path).where((
            path,
          ) {
            final p = path.toLowerCase();
            return p.endsWith('.jpg') ||
                p.endsWith('.jpeg') ||
                p.endsWith('.png');
          }).toList();

          if (imagePaths.isNotEmpty && !_purchaseService.isProUnlocked) {
            await showProDialog();
            return;
          }

          if (imagePaths.length > 1) {
            final outputPath = await FilePicker.platform.saveFile(
              lockParentWindow: true,
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
              showMessage('Bilder konnten nicht umgewandelt werden: $error');
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
              lockParentWindow: true,
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
              onImageToPdf: kIsWeb
                  ? () => showMessage(
                      'Bild → PDF wird für die Browserversion vorbereitet.',
                    )
                  : () => _runProAction(pickImageAndCreatePdf),
              onSave: selectedFilePath == null || kIsWeb
                  ? null
                  : () => _runProAction(saveCurrentPdf),
              onPrint: selectedFilePath == null || kIsWeb
                  ? null
                  : () => _runProAction(printCurrentPdf),
              onClose: selectedFilePath == null ? null : closeCurrentPdf,
              onDeletePage: selectedFilePath == null || kIsWeb
                  ? null
                  : () => _runProAction(confirmDeletePage),
              onRotatePage: selectedFilePath == null || kIsWeb
                  ? null
                  : () => _runProAction(rotateCurrentPage),
              onExtractPage: selectedFilePath == null || kIsWeb
                  ? null
                  : () => _runProAction(extractCurrentPage),
              onExportPageAsPng: selectedFilePath == null || kIsWeb
                  ? null
                  : () => _runProAction(exportCurrentPageAsPng),
              onExportPageRangeAsPng: selectedFilePath == null || kIsWeb
                  ? null
                  : () => _runProAction(exportPageRangeAsPng),
              onSplitPdf: selectedFilePath == null || kIsWeb
                  ? null
                  : () => _runProAction(splitPdfByPageRange),
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
