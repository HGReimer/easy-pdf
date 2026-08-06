import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewPanel extends StatelessWidget {
  const PdfViewPanel({
    super.key,
    required this.filePath,
  });

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return SfPdfViewer.file(
      File(filePath),
    );
  }
}