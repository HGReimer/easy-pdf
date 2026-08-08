import 'package:flutter/material.dart';

class PdfToolbar extends StatelessWidget {
  const PdfToolbar({
    super.key,
    required this.onOpen,
    this.onDeletePage,
  });

  final VoidCallback onOpen;
  final VoidCallback? onDeletePage;

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

          IconButton(
            onPressed: null,
            icon: const Icon(Icons.save),
            tooltip: "Speichern",
          ),

          IconButton(
            onPressed: onDeletePage,
            icon: const Icon(Icons.delete),
            tooltip: "Seite löschen",
          ),

          IconButton(
            onPressed: null,
            icon: const Icon(Icons.rotate_right),
            tooltip: "Seite drehen",
          ),

          IconButton(
            onPressed: null,
            icon: const Icon(Icons.content_cut),
            tooltip: "Seite extrahieren",
          ),
        ],
      ),
    );
  }
}