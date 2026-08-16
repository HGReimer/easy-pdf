import 'package:flutter/material.dart';

class PdfToolbar extends StatelessWidget {
  const PdfToolbar({
    super.key,
    required this.onOpen,
    required this.onImageToPdf,
    this.onSave,
    this.onClose,
    this.onDeletePage,
    this.onRotatePage,
    this.onExtractPage,
    this.onSplitPdf,
    this.onPreviousPage,
    this.onNextPage,
    required this.selectedPage,
    required this.pageCount,
  });

  final VoidCallback onOpen;
  final VoidCallback onImageToPdf;
  final VoidCallback? onSave;
  final VoidCallback? onClose;
  final VoidCallback? onDeletePage;
  final VoidCallback? onRotatePage;
  final VoidCallback? onExtractPage;
  final VoidCallback? onSplitPdf;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final int selectedPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.folder_open),
            label: const Text("Öffnen"),
          ),
          const SizedBox(width: 8),

          FilledButton.tonalIcon(
            onPressed: onImageToPdf,
            icon: const Icon(Icons.image),
            label: const Text("Bild → PDF"),
          ),
          const SizedBox(width: 8),

          IconButton(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            tooltip: "Speichern",
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            tooltip: "PDF schließen",
          ),

          IconButton(
            onPressed: onDeletePage,
            icon: const Icon(Icons.delete),
            tooltip: "Seite löschen",
          ),

          IconButton(
            onPressed: onRotatePage,
            icon: const Icon(Icons.rotate_right),
            tooltip: "Seite drehen",
          ),

          IconButton(
            onPressed: onExtractPage,
            icon: const Icon(Icons.content_cut),
            tooltip: "Seite extrahieren",
          ),
          IconButton(
            onPressed: onSplitPdf,
            icon: const Icon(Icons.call_split),
            tooltip: "PDF teilen",
          ),

          const Spacer(),

          IconButton(
            onPressed: onPreviousPage,
            icon: const Icon(Icons.chevron_left),
            tooltip: "Vorherige Seite",
          ),

          Text(
            pageCount > 0 ? "$selectedPage / $pageCount" : "– / –",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          IconButton(
            onPressed: onNextPage,
            icon: const Icon(Icons.chevron_right),
            tooltip: "Nächste Seite",
          ),
        ],
      ),
    );
  }
}
