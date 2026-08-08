import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewPanel extends StatefulWidget {
  const PdfViewPanel({
    super.key,
    required this.filePath,
    required this.selectedPage,
  });

  final String filePath;
  final int selectedPage;

  @override
  State<PdfViewPanel> createState() => _PdfViewPanelState();
}

class _PdfViewPanelState extends State<PdfViewPanel> {
  final PdfViewerController _controller = PdfViewerController();

  @override
  void didUpdateWidget(covariant PdfViewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedPage != widget.selectedPage) {
      _controller.jumpToPage(widget.selectedPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SfPdfViewer.file(
      File(widget.filePath),
      controller: _controller,
    );
  }
}