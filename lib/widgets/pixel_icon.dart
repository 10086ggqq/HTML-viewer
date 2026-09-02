import 'package:flutter/material.dart';

/// Available hand-drawn pixel art pieces.
enum PixelArt { grassBlock, chest, barrel }

class _PixelArtData {
  const _PixelArtData(this.palette, this.rows);

  final Map<String, Color> palette;
  final List<String> rows;
}

const Map<PixelArt, _PixelArtData> _artData = {
  PixelArt.grassBlock: _PixelArtData(
    {
      'G': Color(0xFF7CBD5B),
      'g': Color(0xFF93CF6E),
      'D': Color(0xFF9B6A44),
      'd': Color(0xFF7F5433),
    },
    [
      'GGGGGGGG',
      'GgGGgGGg',
      'DdDDDdDD',
      'DDDdDDDD',
      'DdDDDDdD',
      'DDDDdDDD',
      'DdDDDdDD',
      'DDDDDDdD',
    ],
  ),
  PixelArt.chest: _PixelArtData(
    {
      'o': Color(0xFF5C3F1E),
      'L': Color(0xFFA9782F),
      'l': Color(0xFF8A5F2A),
      'g': Color(0xFFF2C14E),
    },
    [
      'oooooooo',
      'oLLLLLLo',
      'oLlLLlLo',
      'oooooooo',
      'oLLgLLLo',
      'oLlLLlLo',
      'oLLLLLLo',
      'oooooooo',
    ],
  ),
  PixelArt.barrel: _PixelArtData(
    {
      'o': Color(0xFF4E3818),
      'L': Color(0xFF8A5F2A),
      'l': Color(0xFF74491F),
      's': Color(0xFFB8B8B8),
    },
    [
      'oooooooo',
      'oLLLLLLo',
      'oosssoLo',
      'oLLLLLLo',
      'oLlLLlLo',
      'oossssoo',
      'oLLLLLLo',
      'oooooooo',
    ],
  ),
};

/// Paints [rows] as a pixel grid snapped to whole pixels to avoid seams.
void _paintPixelGrid(
  Canvas canvas,
  Size size,
  List<String> rows,
  Map<String, Color> palette,
) {
  final grid = rows.length;
  final paint = Paint()..isAntiAlias = false;
  final cellW = size.width / grid;
  final cellH = size.height / grid;
  for (var y = 0; y < grid; y++) {
    final row = rows[y];
    final top = (y * cellH).floorToDouble();
    final bottom =
        y == grid - 1 ? size.height : ((y + 1) * cellH).floorToDouble();
    for (var x = 0; x < row.length; x++) {
      final color = palette[row[x]];
      if (color == null) continue;
      final left = (x * cellW).floorToDouble();
      final right =
          x == row.length - 1 ? size.width : ((x + 1) * cellW).floorToDouble();
      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint..color = color);
    }
  }
}

/// A pixel-art icon painted with [CustomPainter] (no image assets).
class PixelIcon extends StatelessWidget {
  const PixelIcon({
    super.key,
    required this.art,
    this.size = 48,
    this.semanticLabel,
  });

  final PixelArt art;
  final double size;

  /// Accessibility label announced by screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PixelArtPainter(art)),
      ),
    );
  }
}

class _PixelArtPainter extends CustomPainter {
  _PixelArtPainter(this.art);

  final PixelArt art;

  @override
  void paint(Canvas canvas, Size size) {
    final data = _artData[art]!;
    _paintPixelGrid(canvas, size, data.rows, data.palette);
  }

  @override
  bool shouldRepaint(_PixelArtPainter oldDelegate) => oldDelegate.art != art;
}

/// A pixel file icon: white paper with a colored band and a text badge,
/// e.g. `</>` for HTML, `#` for CSS, `JS` for JavaScript.
class PixelFileIcon extends StatelessWidget {
  const PixelFileIcon({
    super.key,
    required this.badge,
    required this.color,
    this.size = 40,
  });

  final String badge;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _FilePaperPainter(color)),
          Center(
            child: Text(
              badge,
              style: TextStyle(
                fontSize: size * 0.22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilePaperPainter extends CustomPainter {
  _FilePaperPainter(this.bandColor);

  final Color bandColor;

  static const _rows = [
    'oooooooo',
    'oppppppo',
    'oppppppo',
    'oCCCCCCo',
    'oCCCCCCo',
    'oppppppo',
    'oppppppo',
    'oooooooo',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _paintPixelGrid(canvas, size, _rows, {
      'o': const Color(0xFF26241E),
      'p': Colors.white,
      'C': bandColor,
    });
  }

  @override
  bool shouldRepaint(_FilePaperPainter oldDelegate) =>
      oldDelegate.bandColor != bandColor;
}
