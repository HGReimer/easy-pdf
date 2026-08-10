import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class ThumbnailPanel extends StatefulWidget {
  const ThumbnailPanel({
    super.key,
    required this.filePath,
    required this.selectedPage,
    required this.onPageSelected,
    required this.onPageReordered,
  });

  final String filePath;
  final int selectedPage;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<List<int>> onPageReordered;

  @override
  State<ThumbnailPanel> createState() => _ThumbnailPanelState();
}

class _ThumbnailPanelState extends State<ThumbnailPanel> {
  List<int>? pageOrder;

  @override
  void didUpdateWidget(covariant ThumbnailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.filePath != widget.filePath) {
      pageOrder = null;
    }
  }

  void movePage(int fromIndex, int toIndex) {
    final order = pageOrder;

    if (order == null ||
        fromIndex == toIndex ||
        fromIndex < 0 ||
        fromIndex >= order.length ||
        toIndex < 0 ||
        toIndex >= order.length) {
      return;
    }

    setState(() {
      final pageNumber = order.removeAt(fromIndex);
      order.insert(toIndex, pageNumber);
    });

    widget.onPageReordered(List<int>.from(order));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      color: Colors.grey.shade200,
      child: PdfDocumentViewBuilder.file(
        widget.filePath,
        builder: (context, document) {
          if (document == null) {
            return const Center(child: CircularProgressIndicator());
          }

          pageOrder ??= List<int>.generate(
            document.pages.length,
            (index) => index + 1,
          );

          final order = pageOrder!;

          return ListView.builder(
            itemCount: order.length,
            itemBuilder: (context, index) {
              final pageNumber = order[index];
              final isSelected = pageNumber == widget.selectedPage;

              return DragTarget<int>(
                onWillAcceptWithDetails: (details) {
                  return details.data != index;
                },
                onAcceptWithDetails: (details) {
                  movePage(details.data, index);
                },
                builder: (context, candidateData, rejectedData) {
                  final isTarget = candidateData.isNotEmpty;

                  return Draggable<int>(
                    data: index,
                    feedback: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 130,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Seite $pageNumber',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: buildThumbnail(
                        document,
                        pageNumber,
                        isSelected,
                        isTarget,
                      ),
                    ),
                    child: buildThumbnail(
                      document,
                      pageNumber,
                      isSelected,
                      isTarget,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget buildThumbnail(
    PdfDocument document,
    int pageNumber,
    bool isSelected,
    bool isTarget,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => widget.onPageSelected(pageNumber),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red.shade100 : Colors.white,
            border: Border.all(
              color: isTarget
                  ? Colors.blue
                  : isSelected
                  ? Colors.red
                  : Colors.grey.shade400,
              width: isTarget || isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                child: PdfPageView(
                  document: document,
                  pageNumber: pageNumber,
                  alignment: Alignment.center,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.drag_indicator, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Seite $pageNumber',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
