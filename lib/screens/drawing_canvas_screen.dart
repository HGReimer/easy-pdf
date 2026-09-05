import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingCanvasScreen extends StatefulWidget {
  const DrawingCanvasScreen({super.key});

  @override
  State<DrawingCanvasScreen> createState() => _DrawingCanvasScreenState();
}

class _DrawingCanvasScreenState extends State<DrawingCanvasScreen> {
  final GlobalKey _repaintKey = GlobalKey();

  final List<_Stroke> _strokes = [];
  final List<_Stroke> _redoStack = [];

  _Stroke? _currentStroke;

  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isEraser = false;

  void _onPanStart(DragStartDetails details) {
    final stroke = _Stroke(
      points: [details.localPosition],
      color: _isEraser ? Colors.white : _selectedColor,
      width: _isEraser ? _strokeWidth * 3 : _strokeWidth,
    );

    setState(() {
      _currentStroke = stroke;
      _strokes.add(stroke);
      _redoStack.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null) return;

    setState(() {
      _currentStroke!.points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _currentStroke = null;
  }

  void _undo() {
    if (_strokes.isEmpty) return;

    setState(() {
      _redoStack.add(_strokes.removeLast());
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    setState(() {
      _strokes.add(_redoStack.removeLast());
    });
  }

  void _clear() {
    if (_strokes.isEmpty) return;

    setState(() {
      _redoStack.addAll(_strokes);
      _strokes.clear();
    });
  }

  Future<Uint8List?> _exportAsPng() async {
    final boundary =
        _repaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;

    if (boundary == null) return null;

    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);

    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) return null;

    return byteData.buffer.asUint8List();
  }

  Future<void> _finishAndReturn() async {
    if (_strokes.isEmpty) {
      Navigator.pop(context, null);
      return;
    }

    final png = await _exportAsPng();

    if (!mounted) return;

    Navigator.pop(context, png);
  }

  void _showColorPicker() {
    final colors = <Color>[
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 18,
              runSpacing: 18,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                      _isEraser = false;
                    });

                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color && !_isEraser
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showStrokeWidthPicker() {
    double tempWidth = _strokeWidth;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Strichstärke: ${tempWidth.toStringAsFixed(0)}'),
                    Slider(
                      value: tempWidth,
                      min: 1,
                      max: 12,
                      divisions: 11,
                      onChanged: (value) {
                        setSheetState(() {
                          tempWidth = value;
                        });
                      },
                    ),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _strokeWidth = tempWidth;
                        });

                        Navigator.pop(context);
                      },
                      child: const Text('Übernehmen'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zeichnung'),
        actions: [
          IconButton(
            tooltip: 'Rückgängig',
            onPressed: _strokes.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Wiederholen',
            onPressed: _redoStack.isEmpty ? null : _redo,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'Alles löschen',
            onPressed: _strokes.isEmpty ? null : _clear,
            icon: const Icon(Icons.delete_outline),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _finishAndReturn,
              child: const Text('Übernehmen'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            elevation: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  _ToolButton(
                    icon: Icons.edit,
                    label: 'Stift',
                    selected: !_isEraser,
                    onPressed: () {
                      setState(() {
                        _isEraser = false;
                      });
                    },
                  ),
                  _ToolButton(
                    icon: Icons.cleaning_services_outlined,
                    label: 'Radierer',
                    selected: _isEraser,
                    onPressed: () {
                      setState(() {
                        _isEraser = true;
                      });
                    },
                  ),
                  _ToolButton(
                    icon: Icons.palette_outlined,
                    label: 'Farbe',
                    color: _selectedColor,
                    onPressed: _showColorPicker,
                  ),
                  _ToolButton(
                    icon: Icons.line_weight,
                    label: 'Stärke',
                    onPressed: _showStrokeWidthPicker,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    painter: _StrokesPainter(_strokes),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stroke {
  _Stroke({required this.points, required this.color, required this.width});

  final List<Offset> points;
  final Color color;
  final double width;
}

class _StrokesPainter extends CustomPainter {
  const _StrokesPainter(this.strokes);

  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first,
          stroke.width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }

      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter oldDelegate) => true;
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(label),
        style: selected
            ? FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              )
            : null,
      ),
    );
  }
}
