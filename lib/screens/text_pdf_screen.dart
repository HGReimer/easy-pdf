import 'dart:convert';

import 'package:flutter/material.dart';

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
  final _bodyController = TextEditingController();

  String _fontFamily = 'Helvetica';
  double _fontSize = 12;
  bool _bold = false;
  bool _italic = false;
  bool _underline = false;
  TextAlign _alignment = TextAlign.left;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    final body = _bodyController.text.trim();

    if (body.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bitte Text eingeben.')));
      return;
    }

    final data = {
      'text': body,
      'fontFamily': _fontFamily,
      'fontSize': _fontSize,
      'bold': _bold,
      'italic': _italic,
      'underline': _underline,
      'alignment': _alignment.name,
    };

    final result = TextPdfResult(
      title: _titleController.text.trim(),
      deltaJson: jsonEncode(data),
    );

    FocusManager.instance.primaryFocus?.unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(result);
    });
  }

  Widget _formatButton({
    required IconData icon,
    required String tooltip,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily: _fontFamily == 'Helvetica' ? null : _fontFamily,
      fontSize: _fontSize,
      fontWeight: _bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: _italic ? FontStyle.italic : FontStyle.normal,
      decoration: _underline ? TextDecoration.underline : TextDecoration.none,
    );

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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _fontFamily,
                  items: const [
                    DropdownMenuItem(
                      value: 'Helvetica',
                      child: Text('Helvetica'),
                    ),
                    DropdownMenuItem(value: 'Times', child: Text('Times')),
                    DropdownMenuItem(value: 'Courier', child: Text('Courier')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _fontFamily = value;
                      });
                    }
                  },
                ),
                const SizedBox(width: 12),
                DropdownButton<double>(
                  value: _fontSize,
                  items: const [
                    DropdownMenuItem(value: 8, child: Text('8')),
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 12, child: Text('12')),
                    DropdownMenuItem(value: 14, child: Text('14')),
                    DropdownMenuItem(value: 16, child: Text('16')),
                    DropdownMenuItem(value: 18, child: Text('18')),
                    DropdownMenuItem(value: 24, child: Text('24')),
                    DropdownMenuItem(value: 32, child: Text('32')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _fontSize = value;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                _formatButton(
                  icon: Icons.format_bold,
                  tooltip: 'Fett',
                  selected: _bold,
                  onPressed: () {
                    setState(() {
                      _bold = !_bold;
                    });
                  },
                ),
                _formatButton(
                  icon: Icons.format_italic,
                  tooltip: 'Kursiv',
                  selected: _italic,
                  onPressed: () {
                    setState(() {
                      _italic = !_italic;
                    });
                  },
                ),
                _formatButton(
                  icon: Icons.format_underline,
                  tooltip: 'Unterstrichen',
                  selected: _underline,
                  onPressed: () {
                    setState(() {
                      _underline = !_underline;
                    });
                  },
                ),
                _formatButton(
                  icon: Icons.format_align_left,
                  tooltip: 'Linksbündig',
                  selected: _alignment == TextAlign.left,
                  onPressed: () {
                    setState(() {
                      _alignment = TextAlign.left;
                    });
                  },
                ),
                _formatButton(
                  icon: Icons.format_align_center,
                  tooltip: 'Zentriert',
                  selected: _alignment == TextAlign.center,
                  onPressed: () {
                    setState(() {
                      _alignment = TextAlign.center;
                    });
                  },
                ),
                _formatButton(
                  icon: Icons.format_align_right,
                  tooltip: 'Rechtsbündig',
                  selected: _alignment == TextAlign.right,
                  onPressed: () {
                    setState(() {
                      _alignment = TextAlign.right;
                    });
                  },
                ),
                _formatButton(
                  icon: Icons.format_align_justify,
                  tooltip: 'Blocksatz',
                  selected: _alignment == TextAlign.justify,
                  onPressed: () {
                    setState(() {
                      _alignment = TextAlign.justify;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _bodyController,
                expands: true,
                minLines: null,
                maxLines: null,
                textAlign: _alignment,
                textAlignVertical: TextAlignVertical.top,
                style: textStyle,
                decoration: const InputDecoration(
                  hintText: 'Hier den Text eingeben ...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
