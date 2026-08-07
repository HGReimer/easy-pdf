import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class ThumbnailPanel extends StatelessWidget {
  const ThumbnailPanel({
    super.key,
    required this.filePath,
    required this.selectedPage,
    required this.onPageSelected,
  });

  final String filePath;
  final int selectedPage;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      color: Colors.grey.shade200,
      child: PdfDocumentViewBuilder.file(
        filePath,
        builder: (context, document) {
          if (document == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView.builder(
            itemCount: document.pages.length,
            itemBuilder: (context, index) {
              final pageNumber = index + 1;
              final isSelected = pageNumber == selectedPage;

              return Padding(
                padding: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () => onPageSelected(pageNumber),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.red.shade100
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? Colors.red
                            : Colors.grey.shade400,
                        width: isSelected ? 2 : 1,
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
                        Text(
                          'Seite $pageNumber',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}