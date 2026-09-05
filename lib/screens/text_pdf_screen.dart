import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class TextPdfResult {
  const TextPdfResult({required this.title, required this.deltaJson});

  final String title;
  final String deltaJson;
}

class TextPdfScreen extends StatefulWidget {
  const TextPdfScreen({super.key});

  @override
  State<TextPdfScreen> createState() => _TextPdfScreenState();
}

class _TextPdfScreenState extends State<TextPdfScreen> {
  final _titleController = TextEditingController();

  late final QuillController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final plainText = _controller.document.toPlainText().trim();

    if (plainText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bitte Text eingeben.')));
      return;
    }

    final deltaJson = jsonEncode(_controller.document.toDelta().toJson());

    Navigator.pop(
      context,
      TextPdfResult(title: _titleController.text.trim(), deltaJson: deltaJson),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF aus Text erstellen'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Erstellen'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Dokumenttitel',
                hintText: 'Optional',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: QuillSimpleToolbar(
              controller: _controller,
              config: const QuillSimpleToolbarConfig(
                showFontFamily: true,
                showFontSize: true,
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showAlignmentButtons: true,
                showLeftAlignment: true,
                showCenterAlignment: true,
                showRightAlignment: true,
                showJustifyAlignment: true,
                showUndo: true,
                showRedo: true,
                showClearFormat: true,
                multiRowsDisplay: true,
                showStrikeThrough: false,
                showInlineCode: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showHeaderStyle: false,
                showListNumbers: false,
                showListBullets: false,
                showListCheck: false,
                showCodeBlock: false,
                showQuote: false,
                showIndent: false,
                showLink: false,
                showSearchButton: false,
                showDirection: false,
                showSubscript: false,
                showSuperscript: false,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: _scrollController,
                config: const QuillEditorConfig(padding: EdgeInsets.all(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
