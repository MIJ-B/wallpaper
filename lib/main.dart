import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const SkeletonApp());
}

class SkeletonApp extends StatelessWidget {
  const SkeletonApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Skeleton Bibilava 3D',
      theme: ThemeData.dark(),
      home: const SkeletonScreen(),
    );
  }
}

class SkeletonScreen extends StatefulWidget {
  const SkeletonScreen({Key? key}) : super(key: key);

  @override
  State<SkeletonScreen> createState() => _SkeletonScreenState();
}

class _SkeletonScreenState extends State<SkeletonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragPosition = Offset.zero;
  Offset _lastDragPosition = Offset.zero;
  bool _isDragging = false;
  late SnakeSkeleton _snake;
  double _globeRotationX = 0.3;
  double _globeRotationY = 0;
  Offset _lastPanPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(() {
      setState(() {
        if (!_isDragging) {
          _globeRotationY += 0.005; // Auto-rotate globe only
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    _dragPosition = Offset(size.width / 2, size.height / 2);
    _lastDragPosition = _dragPosition;
    _snake = SnakeSkeleton(25, _dragPosition);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    _snake.update(_dragPosition);

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1a),
      body: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
            _dragPosition = details.localPosition;
            _lastDragPosition = _dragPosition;
            _lastPanPosition = details.localPosition;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            if (details.localPosition.dx < size.width * 0.3 ||
                details.localPosition.dx > size.width * 0.7 ||
                details.localPosition.dy < size.height * 0.3 ||
                details.localPosition.dy > size.height * 0.7) {
              // Rotate globe when near edges
              final delta = details.localPosition - _lastPanPosition;
              _globeRotationY += delta.dx * 0.01;
              _globeRotationX -= delta.dy * 0.01;
              _globeRotationX = _globeRotationX.clamp(-math.pi / 2, math.pi / 2);
            } else {
              // Move skeleton when in center
              _dragPosition = details.localPosition;
              _lastDragPosition = _dragPosition;
            }
            _lastPanPosition = details.localPosition;
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        child: CustomPaint(
          size: size,
          painter: SkeletonPainter(
            _snake,
            _globeRotationX,
            _globeRotationY,
          ),
        ),
      ),
    );
  }
}

class Leg {
  final String side;
  final int vertebraIndex;
  final int totalVertebrae;
  final int numSegments = 3;
  late double baseLength;
  late double segmentLength;
  List<LegSegment> segments = [];

  Leg(this.side, this.vertebraIndex, this.totalVertebrae) {
    final progress = vertebraIndex / totalVertebrae;
    baseLength = 25 - (progress * 18);
    segmentLength = baseLength / numSegments;
  }

  void update(Offset base, double angle, double walkPhase) {
    final legAngle = angle + (side == 'left' ? math.pi / 2 : -math.pi / 2);
    final walkOffset = vertebraIndex * 0.5;
    final walk = math.sin(walkPhase + walkOffset + (side == 'left' ? 0 : math.pi)) * 0.4;

    segments.clear();
    double x = base.dx;
    double y = base.dy;

    for (int i = 0; i < numSegments; i++) {
      final segAngle = legAngle + walk + (i * 0.3);
      final nextX = x + math.cos(segAngle) * segmentLength;
      final nextY = y + math.sin(segAngle) * segmentLength;

      segments.add(LegSegment(
        start: Offset(x, y),
        end: Offset(nextX, nextY),
      ));

      x = nextX;
      y = nextY;
    }
  }

  void draw(Canvas canvas, double progress) {
    final thickness = 3.0 - (progress * 1.5);
    final paint = Paint()
      ..color = const Color(0xFFB0B0B0)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var seg in segments) {
      canvas.drawLine(seg.start, seg.end, paint);

      final jointSize = 4.0 - (progress * 2);
      final jointPaint = Paint()
        ..color = const Color(0xFFD0D0D0)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(seg.start, jointSize, jointPaint);
    }

    if (segments.isNotEmpty) {
      final lastSeg = segments.last;
      final clawPaint = Paint()
        ..color = const Color(0xFF888888)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round;

      final numClaws = progress < 0.5 ? 3 : 2;
      for (int i = 0; i < numClaws; i++) {
        final angle = math.atan2(
          lastSeg.end.dy - lastSeg.start.dy,
          lastSeg.end.dx - lastSeg.start.dx,
        );
        final clawAngle = angle + (i - 1) * 0.3;
        final clawLength = 8.0 - (progress * 4);
        final clawEnd = Offset(
          lastSeg.end.dx + math.cos(clawAngle) * clawLength,
          lastSeg.end.dy + math.sin(clawAngle) * clawLength,
        );

        canvas.drawLine(lastSeg.end, clawEnd, clawPaint);
      }
    }
  }
}

class LegSegment {
  final Offset start;
  final Offset end;

  LegSegment({required this.start, required this.end});
}

class Vertebra {
  Offset position;
  double size;
  double angle;
  final int index;
  final int total;
  final List<Leg> legs = [];

  Vertebra({
    required this.position,
    required this.size,
    required this.angle,
    required this.index,
    required this.total,
  }) {
    if (index >= 2 && index < total - 3) {
      legs.add(Leg('left', index, total));
      legs.add(Leg('right', index, total));
    }
  }

  void follow(Offset target) {
    final dx = target.dx - position.dx;
    final dy = target.dy - position.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance > 0) {
      angle = math.atan2(dy, dx);

      final spacing = size * 0.8;
      if (distance > spacing) {
        position = Offset(
          target.dx - math.cos(angle) * spacing,
          target.dy - math.sin(angle) * spacing,
        );
      }
    }
  }

  void draw(Canvas canvas, double walkPhase) {
    final progress = index / total;
    final currentSize = size * (1 - progress * 0.3);

    for (var leg in legs) {
      leg.update(position, angle, walkPhase);
      leg.draw(canvas, progress);
    }

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);

    final bodyPaint = Paint()
      ..color = const Color(0xFFD8D8D8)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: currentSize * 3,
        height: currentSize * 2,
      ),
      bodyPaint,
    );

    final strokePaint = Paint()
      ..color = const Color(0xFF666666)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: currentSize * 3,
        height: currentSize * 2,
      ),
      strokePaint,
    );

    final canalPaint = Paint()..color = Colors.black;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: currentSize,
        height: currentSize * 0.6,
      ),
      canalPaint,
    );

    final transverseLength = currentSize * 2;
    final transverseWidth = currentSize * 0.6;
    final transversePaint = Paint()..color = const Color(0xFFC8C8C8);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-transverseLength, 0),
        width: transverseWidth * 2,
        height: transverseWidth * 1.2,
      ),
      transversePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-transverseLength, 0),
        width: transverseWidth * 2,
        height: transverseWidth * 1.2,
      ),
      strokePaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(transverseLength, 0),
        width: transverseWidth * 2,
        height: transverseWidth * 1.2,
      ),
      transversePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(transverseLength, 0),
        width: transverseWidth * 2,
        height: transverseWidth * 1.2,
      ),
      strokePaint,
    );

    canvas.restore();
  }
}

class SnakeSkeleton {
  final List<Vertebra> vertebrae = [];
  final int numVertebrae;
  final double baseSize = 20;
  double walkPhase = 0;

  SnakeSkeleton(this.numVertebrae, Offset initialPosition) {
    for (int i = 0; i < numVertebrae; i++) {
      final size = baseSize * (1 - (i / numVertebrae) * 0.5);
      vertebrae.add(Vertebra(
        position: Offset(
          initialPosition.dx - i * size * 0.8,
          initialPosition.dy,
        ),
        size: size,
        angle: 0,
        index: i,
        total: numVertebrae,
      ));
    }
  }

  void update(Offset target) {
    walkPhase += 0.1;
    vertebrae[0].follow(target);

    for (int i = 1; i < vertebrae.length; i++) {
      vertebrae[i].follow(vertebrae[i - 1].position);
    }
  }

  void drawTail(Canvas canvas) {
    final lastVert = vertebrae.last;
    final prevVert = vertebrae[vertebrae.length - 2];

    final angle = math.atan2(
      lastVert.position.dy - prevVert.position.dy,
      lastVert.position.dx - prevVert.position.dx,
    );

    const numTailSegments = 5;
    const segmentLength = 12.0;
    double x = lastVert.position.dx;
    double y = lastVert.position.dy;

    for (int i = 0; i < numTailSegments; i++) {
      final nextX = x + math.cos(angle) * segmentLength;
      final nextY = y + math.sin(angle) * segmentLength;

      final thickness = 3.0 - (i * 0.5);
      final segPaint = Paint()
        ..color = const Color(0xFF555555)
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x, y), Offset(nextX, nextY), segPaint);

      final boneSize = 4.0 - (i * 0.6);
      final bonePaint = Paint()..color = const Color(0xFFD0D0D0);
      canvas.drawCircle(Offset(x, y), boneSize, bonePaint);

      x = nextX;
      y = nextY;
    }

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    final arrowPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.fill;

    final arrowPath = Path()
      ..moveTo(0, 0)
      ..lineTo(25, -8)
      ..lineTo(30, 0)
      ..lineTo(25, 8)
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);

    final arrowStroke = Paint()
      ..color = const Color(0xFF666666)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(arrowPath, arrowStroke);

    final pointPaint = Paint()..color = Colors.white;
    final pointPath = Path()
      ..moveTo(25, -5)
      ..lineTo(35, 0)
      ..lineTo(25, 5)
      ..close();

    canvas.drawPath(pointPath, pointPaint);
    canvas.drawPath(pointPath, arrowStroke);

    final hookPaint = Paint()
      ..color = const Color(0xFF888888)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(20, -6), const Offset(18, -12), hookPaint);
    canvas.drawLine(const Offset(20, 6), const Offset(18, 12), hookPaint);

    final detailPaint = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 1;

    for (int i = 0; i < 3; i++) {
      final xPos = 5.0 + i * 7;
      canvas.drawLine(Offset(xPos, -3), Offset(xPos + 3, -6), detailPaint);
      canvas.drawLine(Offset(xPos, 3), Offset(xPos + 3, 6), detailPaint);
    }

    canvas.restore();
  }

  void drawSkull(Canvas canvas) {
    final head = vertebrae[0];

    canvas.save();
    canvas.translate(head.position.dx, head.position.dy);
    canvas.rotate(head.angle);

    final skullPaint = Paint()..color = const Color(0xFFE8E8E8);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(25, 0), width: 70, height: 40),
      skullPaint,
    );

    final skullStroke = Paint()
      ..color = const Color(0xFF666666)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(25, 0), width: 70, height: 40),
      skullStroke,
    );

    final snoutPath = Path()
      ..moveTo(60, 0)
      ..lineTo(80, -3)
      ..lineTo(80, 3)
      ..close();

    canvas.drawPath(snoutPath, skullPaint);
    canvas.drawPath(snoutPath, skullStroke);

    final orbitPaint = Paint()..color = Colors.black;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(35, -12), width: 20, height: 24),
      orbitPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(35, 12), width: 20, height: 24),
      orbitPaint,
    );

    final eyePaint = Paint()..color = const Color(0xFFFF0000);
    canvas.drawCircle(const Offset(35, -12), 5, eyePaint);
    canvas.drawCircle(const Offset(35, 12), 5, eyePaint);

    final jawPath = Path()
      ..moveTo(-10, 0)
      ..lineTo(60, -10)
      ..lineTo(78, 0)
      ..lineTo(60, 10)
      ..close();

    final jawPaint = Paint()..color = const Color(0xFFD8D8D8);
    canvas.drawPath(jawPath, jawPaint);
    canvas.drawPath(jawPath, skullStroke);

    final fangPaint = Paint()..color = Colors.white;
    final fangStroke = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 2; i++) {
      final x = 55.0 + i * 15;
      final topFang = Path()
        ..moveTo(x, -8)
        ..lineTo(x - 3, -18)
        ..lineTo(x + 3, -18)
        ..close();

      canvas.drawPath(topFang, fangPaint);
      canvas.drawPath(topFang, fangStroke);

      final bottomFang = Path()
        ..moveTo(x, 8)
        ..lineTo(x - 3, 18)
        ..lineTo(x + 3, 18)
        ..close();

      canvas.drawPath(bottomFang, fangPaint);
      canvas.drawPath(bottomFang, fangStroke);
    }

    for (int i = 0; i < 3; i++) {
      final x = 48.0 + i * 6;
      final topTooth = Path()
        ..moveTo(x, -6)
        ..lineTo(x - 1.5, -11)
        ..lineTo(x + 1.5, -11)
        ..close();

      canvas.drawPath(topTooth, fangPaint);
      canvas.drawPath(topTooth, fangStroke);

      final bottomTooth = Path()
        ..moveTo(x, 6)
        ..lineTo(x - 1.5, 11)
        ..lineTo(x + 1.5, 11)
        ..close();

      canvas.drawPath(bottomTooth, fangPaint);
      canvas.drawPath(bottomTooth, fangStroke);
    }

    final crackPaint = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(10, -18), const Offset(45, -18), crackPaint);
    canvas.drawLine(const Offset(10, 18), const Offset(45, 18), crackPaint);
    canvas.drawLine(const Offset(20, 0), const Offset(15, -10), crackPaint);

    canvas.restore();
  }
}

class Globe3D {
  final double radius;
  final int latLines = 18;
  final int lonLines = 36;

  Globe3D(this.radius);

  void draw(Canvas canvas, Size size, double rotX, double rotY) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw filled sphere with gradient
    final spherePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1a4d2e),
          const Color(0xFF0d2818),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, spherePaint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF2a5a3e).withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Latitude lines
    for (int i = 0; i < latLines; i++) {
      final lat = (i / latLines) * math.pi - math.pi / 2;
      final y = math.sin(lat) * radius;
      final r = math.cos(lat) * radius;

      final path = Path();
      bool firstPoint = true;

      for (int j = 0; j <= lonLines; j++) {
        final lon = (j / lonLines) * 2 * math.pi;
        final point = _project3D(r * math.cos(lon), y, r * math.sin(lon), rotX, rotY);

        if (point != null) {
          final screenPos = Offset(
            center.dx + point.dx,
            center.dy + point.dy,
          );

          if (firstPoint) {
            path.moveTo(screenPos.dx, screenPos.dy);
            firstPoint = false;
          } else {
            path.lineTo(screenPos.dx, screenPos.dy);
          }
        }
      }

      canvas.drawPath(path, gridPaint);
    }

    // Longitude lines
    for (int i = 0; i < lonLines; i++) {
      final lon = (i / lonLines) * 2 * math.pi;

      final path = Path();
      bool firstPoint = true;

      for (int j = 0; j <= latLines; j++) {
        final lat = (j / latLines) * math.pi - math.pi / 2;
        final y = math.sin(lat) * radius;
        final r = math.cos(lat) * radius;

        final point = _project3D(r * math.cos(lon), y, r * math.sin(lon), rotX, rotY);

        if (point != null) {
          final screenPos = Offset(
            center.dx + point.dx,
            center.dy + point.dy,
          );

          if (firstPoint) {
            path.moveTo(screenPos.dx, screenPos.dy);
            firstPoint = false;
          } else {
            path.lineTo(screenPos.dx, screenPos.dy);
          }
        }
      }

      canvas.drawPath(path, gridPaint);
    }

    // Draw continents (simplified)
    _drawContinents(canvas, center, rotX, rotY);

    // Atmosphere glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF4a9d6f).withOpacity(0.0),
          const Color(0xFF4a9d6f).withOpacity(0.3),
        ],
        stops: const [0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius + 20));

    canvas.drawCircle(center, radius + 20, glowPaint);
  }

  Offset? _project3D(double x, double y, double z, double rotX, double rotY) {
    // Rotate around Y axis
    final x1 = x * math.cos(rotY) - z * math.sin(rotY);
    final z1 = x * math.sin(rotY) + z * math.cos(rotY);

    // Rotate around X axis
    final y2 = y * math.cos(rotX) - z1 * math.sin(rotX);
    final z2 = y * math.sin(rotX) + z1 * math.cos(rotX);

    // Check if point is visible (front of sphere)
    if (z2 < -radius * 0.1) return null;

    return Offset(x1, y2);
  }

  void _drawContinents(Canvas canvas, Offset center, double rotX, double rotY) {
    final continentPaint = Paint()
      ..color = const Color(0xFF3a7a54)
      ..style = PaintingStyle.fill;

    // Simplified continent shapes (Africa, Americas, Eurasia)
    final continents = [
      // Africa
      [
        [0.0, 0.3],
        [0.1, 0.2],
        [0.15, 0.0],
        [0.1, -0.3],
        [-0.1, -0.2],
      ],
      // South America
      [
        [-0.6, 0.2],
        [-0.5, 0.4],
        [-0.55, 0.0],
        [-0.6, -0.2],
      ],
      // North America
      [
        [-0.8, 0.5],
        [-0.7, 0.7],
        [-0.9, 0.8],
        [-1.0, 0.6],
      ],
    ];

    for (var continent in continents) {
      final path = Path();
      bool firstPoint = true;

      for (var coord in continent) {
        final lon = coord[0] * math.pi;
        final lat = coord[1] * math.pi / 2;

        final y = math.sin(lat) * radius;
        final r = math.cos(lat) * radius;
        final x = r * math.cos(lon);
        final z = r * math.sin(lon);

        final point = _project3D(x, y, z, rotX, rotY);

        if (point != null) {
          final screenPos = Offset(
            center.dx + point.dx,
            center.dy + point.dy,
          );

          if (firstPoint) {
            path.moveTo(screenPos.dx, screenPos.dy);
            firstPoint = false;
          } else {
            path.lineTo(screenPos.dx, screenPos.dy);
          }
        }
      }

      path.close();
      canvas.drawPath(path, continentPaint);
    }
  }
}

class SkeletonPainter extends CustomPainter {
  final SnakeSkeleton snake;
  final double globeRotationX;
  final double globeRotationY;
  late Globe3D globe;

  SkeletonPainter(this.snake, this.globeRotationX, this.globeRotationY) {
    globe = Globe3D(200);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw space background
    final spacePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1a1a3a),
          const Color(0xFF0a0a1a),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), spacePaint);

    // Draw stars
    final starPaint = Paint()..color = Colors.white;
    final random = math.Random(42);
    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final starSize = random.nextDouble() * 2;
      canvas.drawCircle(Offset(x, y), starSize, starPaint);
    }

    // Draw 3D globe
    globe.draw(canvas, size, globeRotationX, globeRotationY);

    // Draw skeleton on top
    final connectionPaint = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < snake.vertebrae.length - 1; i++) {
      final v1 = snake.vertebrae[i];
      final v2 = snake.vertebrae[i + 1];
      canvas.drawLine(v1.position, v2.position, connectionPaint);
    }

    for (int i = snake.vertebrae.length - 1; i >= 0; i--) {
      snake.vertebrae[i].draw(canvas, snake.walkPhase);
    }

    snake.drawTail(canvas);
    snake.drawSkull(canvas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}