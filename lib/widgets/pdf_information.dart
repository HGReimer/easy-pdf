import 'package:flutter/material.dart';

class PdfInformation extends StatelessWidget {
  const PdfInformation({
    super.key,
    required this.fileName,
    required this.pageCount,
    required this.selectedPage,
  });

  final String fileName;
  final int pageCount;
  final int selectedPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      color: Colors.grey.shade200,
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _InformationItem(
            icon: Icons.picture_as_pdf,
            label: 'Datei',
            value: fileName,
          ),
          _InformationItem(
            icon: Icons.layers,
            label: 'Seiten',
            value: '$pageCount',
          ),
          _InformationItem(
            icon: Icons.touch_app,
            label: 'Ausgewählt',
            value: 'Seite $selectedPage',
          ),
        ],
      ),
    );
  }
}

class _InformationItem extends StatelessWidget {
  const _InformationItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.red.shade700,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}