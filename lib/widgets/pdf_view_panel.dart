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

  double _zoomLevel = 1.0;

  void _zoomOut() {
    if (_zoomLevel <= 1.0) {
      return;
    }

    setState(() {
      _zoomLevel = (_zoomLevel - 0.5).clamp(1.0, 3.0);
      _controller.zoomLevel = _zoomLevel;
    });
  }

  void _zoomIn() {
    if (_zoomLevel >= 3.0) {
      return;
    }

    setState(() {
      _zoomLevel = (_zoomLevel + 0.5).clamp(1.0, 3.0);
      _controller.zoomLevel = _zoomLevel;
    });
  }

  @override
  void didUpdateWidget(covariant PdfViewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedPage != widget.selectedPage) {
      _controller.jumpToPage(widget.selectedPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _zoomLevel <= 1.0 ? null : _zoomOut,
                icon: const Icon(Icons.remove),
                tooltip: "Verkleinern",
              ),
              Text(
                "${(_zoomLevel * 100).round()} %",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                onPressed: _zoomLevel == 1.0
                    ? null
                    : () {
                        setState(() {
                          _zoomLevel = 1.0;
                          _controller.zoomLevel = 1.0;
                        });
                      },
                icon: const Icon(Icons.restart_alt),
                tooltip: "Zoom auf 100 % zurücksetzen",
              ),
              IconButton(
                onPressed: _zoomLevel >= 3.0 ? null : _zoomIn,
                icon: const Icon(Icons.add),
                tooltip: "Vergrößern",
              ),
            ],
          ),
        ),
        Expanded(
          child: SfPdfViewer.file(
            File(widget.filePath),
            controller: _controller,
          ),
        ),
      ],
    );
  }
}
