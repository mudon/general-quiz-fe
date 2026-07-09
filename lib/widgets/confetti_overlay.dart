import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool play;

  const ConfettiOverlay({super.key, required this.play});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _pieces = <_ConfettiPiece>[];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
      }
    });

    if (widget.play) _start();
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) _start();
  }

  void _start() {
    _pieces.clear();
    final colors = DeckColors.confettiColors;
    for (int i = 0; i < 50; i++) {
      _pieces.add(_ConfettiPiece(
        color: colors[_rng.nextInt(colors.length)],
        startOffset: Offset(_rng.nextDouble() * 0.4 + 0.3, -0.1),
        endOffset: Offset(
          _rng.nextDouble() * 1.2 - 0.1,
          _rng.nextDouble() * 0.6 + 0.4,
        ),
        rotation: _rng.nextDouble() * 4 * pi,
        size: _rng.nextDouble() * 6 + 4,
        delay: _rng.nextDouble() * 0.3,
        isCircle: _rng.nextBool(),
      ));
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              pieces: _pieces,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPiece {
  final Color color;
  final Offset startOffset;
  final Offset endOffset;
  final double rotation;
  final double size;
  final double delay;
  final bool isCircle;

  _ConfettiPiece({
    required this.color,
    required this.startOffset,
    required this.endOffset,
    required this.rotation,
    required this.size,
    required this.delay,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  _ConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final localProgress =
          ((progress - piece.delay) / (1.0 - piece.delay)).clamp(0.0, 1.0);

      final easedProgress = Curves.easeOut.transform(localProgress);

      final x = ui.lerpDouble(
        piece.startOffset.dx * size.width,
        piece.endOffset.dx * size.width,
        easedProgress,
      )!;
      final y = ui.lerpDouble(
        piece.startOffset.dy * size.height,
        piece.endOffset.dy * size.height,
        easedProgress,
      )!;

      final alpha = (1.0 - easedProgress).clamp(0.0, 1.0);
      final paint = Paint()..color = piece.color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.rotation * easedProgress * (1.0 - easedProgress));

      if (piece.isCircle) {
        canvas.drawCircle(Offset.zero, piece.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: piece.size, height: piece.size * 0.6),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
