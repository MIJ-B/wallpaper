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
      title: 'Skeleton Bibilava',
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
  double _time = 0;
  late SnakeSkeleton _snake;
  double _scale = 1.0;
  double _zoom = 1.0;
  double _globeRotation = 0.0;

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
          _time += 0.01;
        }
        _globeRotation += 0.003;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    
    final screenWidth = size.width;
    final screenHeight = size.height;
    final minDimension = math.min(screenWidth, screenHeight);
    
    _scale = (minDimension / 800).clamp(0.5, 1.5);
    
    _dragPosition = Offset(size.width / 2, size.height / 2);
    _lastDragPosition = _dragPosition;
    _snake = SnakeSkeleton(25, _dragPosition, scale: _scale);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _getAutoPosition(Size size) {
    final pattern = (_time / 10).floor() % 4;
    
    final range = 200 * _scale;
    final smallRange = 150 * _scale;

    switch (pattern) {
      case 0:
        return Offset(
          _lastDragPosition.dx + math.sin(_time) * range,
          _lastDragPosition.dy + math.sin(_time * 2) * smallRange,
        );
      case 1:
        return Offset(
          _lastDragPosition.dx + math.sin(_time * 1.5) * (range * 1.25),
          _lastDragPosition.dy + math.cos(_time * 0.8) * (range * 0.5),
        );
      case 2:
        final radius = (100 + math.sin(_time * 0.5) * 80) * _scale;
        return Offset(
          _lastDragPosition.dx + math.cos(_time * 2) * radius,
          _lastDragPosition.dy + math.sin(_time * 2) * radius,
        );
      case 3:
        return Offset(
          _lastDragPosition.dx + math.sin(_time * 2) * range,
          _lastDragPosition.dy + math.sin(_time * 3) * (range * 0.6),
        );
      default:
        return _lastDragPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final targetPosition = _isDragging ? _dragPosition : _getAutoPosition(size);

    _snake.update(targetPosition);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
            _dragPosition = details.localPosition;
            _lastDragPosition = _dragPosition;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _dragPosition = details.localPosition;
            _lastDragPosition = _dragPosition;
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
            _time = 0;
          });
        },
        child: Stack(
          children: [
            CustomPaint(
              size: size,
              painter: SpaceGlobePainter(_globeRotation, _zoom),
            ),
            Transform.scale(
              scale: _zoom,
              child: CustomPaint(
                size: size,
                painter: SkeletonPainter(_snake),
              ),
            ),
            Positioned(
              bottom: 30,
              right: 30,
              child: Column(
                children: [
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'zoom_in',
                    backgroundColor: Colors.white.withOpacity(0.2),
                    onPressed: () {
                      setState(() {
                        _zoom = (_zoom + 0.1).clamp(0.5, 2.0);
                      });
                    },
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'zoom_out',
                    backgroundColor: Colors.white.withOpacity(0.2),
                    onPressed: () {
                      setState(() {
                        _zoom = (_zoom - 0.1).clamp(0.5, 2.0);
                      });
                    },
                    child: const Icon(Icons.remove, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'reset',
                    backgroundColor: Colors.white.withOpacity(0.2),
                    onPressed: () {
                      setState(() {
                        _zoom = 1.0;
                      });
                    },
                    child: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 30,
              left: 30,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '🦴 Skeleton in Space\nDrag to move\nZoom +/- buttons',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpaceGlobePainter extends CustomPainter {
  final double rotation;
  final double zoom;

  SpaceGlobePainter(this.rotation, this.zoom);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    final starPaint = Paint()..color = Colors.white;
    final random = math.Random(42);
    
    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final starSize = random.nextDouble() * 2 + 0.5;
      
      final twinkle = math.sin(rotation * 10 + i) * 0.5 + 0.5;
      starPaint.color = Colors.white.withOpacity(twinkle * 0.8);
      
      canvas.drawCircle(Offset(x, y), starSize, starPaint);
    }
    
    final globeRadius = (size.width * 0.4) * zoom;
    final globePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 8; i++) {
      final lat = (i / 8) * math.pi;
      final y = center.dy + (globeRadius * math.cos(lat));
      final currentRadius = globeRadius * math.sin(lat);
      
      if (currentRadius > 0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx, y),
            width: currentRadius * 2,
            height: currentRadius * 2 * 0.3,
          ),
          globePaint,
        );
      }
    }
    
    final longitudePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2 + rotation;
      final path = Path();
      
      for (double t = 0; t <= math.pi; t += 0.1) {
        final x = center.dx + globeRadius * math.sin(t) * math.cos(angle);
        final y = center.dy + globeRadius * math.cos(t);
        final z = globeRadius * math.sin(t) * math.sin(angle);
        
        final scale = 1 + z / (globeRadius * 2);
        final projectedX = center.dx + (x - center.dx) * scale;
        final projectedY = center.dy + (y - center.dy) * scale;
        
        if (t == 0) {
          path.moveTo(projectedX, projectedY);
        } else {
          path.lineTo(projectedX, projectedY);
        }
      }
      
      canvas.drawPath(path, longitudePaint);
    }
    
    final glowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, globeRadius, glowPaint);
    
    final particlePaint = Paint()..style = PaintingStyle.fill;
    
    for (int i = 0; i < 30; i++) {
      final orbitAngle = (i / 30) * math.pi * 2 + rotation * 2;
      final orbitRadius = globeRadius * (1.1 + (i % 3) * 0.05);
      
      final px = center.dx + math.cos(orbitAngle) * orbitRadius;
      final py = center.dy + math.sin(orbitAngle) * orbitRadius;
      
      final hue = ((i / 30) * 360 + rotation * 50) % 360;
      particlePaint.color = HSVColor.fromAHSV(0.6, hue, 0.8, 1.0).toColor();
      
      canvas.drawCircle(Offset(px, py), 2, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SpaceGlobePainter oldDelegate) {
    return rotation != oldDelegate.rotation || zoom != oldDelegate.zoom;
  }
}class Leg {
  final String side;
  final int vertebraIndex;
  final int totalVertebrae;
  final int numSegments = 3;
  late double baseLength;
  late double segmentLength;
  final double scale;
  List<LegSegment> segments = [];

  Leg(this.side, this.vertebraIndex, this.totalVertebrae, this.scale) {
    final progress = vertebraIndex / totalVertebrae;
    baseLength = (25 - (progress * 18)) * scale;
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

  void draw(Canvas canvas, double progress, Paint legPaint, Paint jointPaint, Paint clawPaint) {
    final thickness = (3.0 - (progress * 1.5)) * scale;
    legPaint
      ..strokeWidth = thickness
      ..color = const Color(0xFFB0B0B0);

    for (var seg in segments) {
      canvas.drawLine(seg.start, seg.end, legPaint);

      final jointSize = (4.0 - (progress * 2)) * scale;
      jointPaint.color = const Color(0xFFD0D0D0);
      canvas.drawCircle(seg.start, jointSize, jointPaint);
    }

    if (segments.isNotEmpty) {
      final lastSeg = segments.last;
      clawPaint
        ..strokeWidth = 1 * scale
        ..color = const Color(0xFF888888);

      final numClaws = progress < 0.5 ? 3 : 2;
      for (int i = 0; i < numClaws; i++) {
        final angle = math.atan2(
          lastSeg.end.dy - lastSeg.start.dy,
          lastSeg.end.dx - lastSeg.start.dx,
        );
        final clawAngle = angle + (i - 1) * 0.3;
        final clawLength = (8.0 - (progress * 4)) * scale;
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
  final double scale;
  final List<Leg> legs = [];

  Vertebra({
    required this.position,
    required this.size,
    required this.angle,
    required this.index,
    required this.total,
    required this.scale,
  }) {
    if (index >= 2 && index < total - 3) {
      legs.add(Leg('left', index, total, scale));
      legs.add(Leg('right', index, total, scale));
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

  void draw(Canvas canvas, double walkPhase, Paint bodyPaint, Paint strokePaint, 
            Paint canalPaint, Paint transversePaint, Paint legPaint, 
            Paint jointPaint, Paint clawPaint) {
    final progress = index / total;
    final currentSize = size * (1 - progress * 0.3);

    for (var leg in legs) {
      leg.update(position, angle, walkPhase);
      leg.draw(canvas, progress, legPaint, jointPaint, clawPaint);
    }

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);

    bodyPaint.color = const Color(0xFFD8D8D8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: currentSize * 3,
        height: currentSize * 2,
      ),
      bodyPaint,
    );

    strokePaint
      ..strokeWidth = 2 * scale
      ..color = const Color(0xFF666666);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: currentSize * 3,
        height: currentSize * 2,
      ),
      strokePaint,
    );

    canalPaint.color = Colors.black;
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
    transversePaint.color = const Color(0xFFC8C8C8);

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
  final double baseSize;
  final double scale;
  double walkPhase = 0;

  SnakeSkeleton(this.numVertebrae, Offset initialPosition, {this.scale = 1.0})
      : baseSize = 20 * scale {
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
        scale: scale,
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

  void drawTail(Canvas canvas, Paint segPaint, Paint bonePaint, Paint arrowPaint, 
                Paint arrowStroke, Paint pointPaint, Paint hookPaint, Paint detailPaint) {
    final lastVert = vertebrae.last;
    final prevVert = vertebrae[vertebrae.length - 2];

    final angle = math.atan2(
      lastVert.position.dy - prevVert.position.dy,
      lastVert.position.dx - prevVert.position.dx,
    );

    const numTailSegments = 5;
    final segmentLength = 12.0 * scale;
    double x = lastVert.position.dx;
    double y = lastVert.position.dy;

    for (int i = 0; i < numTailSegments; i++) {
      final nextX = x + math.cos(angle) * segmentLength;
      final nextY = y + math.sin(angle) * segmentLength;

      final thickness = (3.0 - (i * 0.5)) * scale;
      segPaint
        ..color = const Color(0xFF555555)
        ..strokeWidth = thickness;

      canvas.drawLine(Offset(x, y), Offset(nextX, nextY), segPaint);

      final boneSize = (4.0 - (i * 0.6)) * scale;
      bonePaint.color = const Color(0xFFD0D0D0);
      canvas.drawCircle(Offset(x, y), boneSize, bonePaint);

      x = nextX;
      y = nextY;
    }

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    arrowPaint.color = const Color(0xFFE0E0E0);

    final arrowPath = Path()
      ..moveTo(0, 0)
      ..lineTo(25 * scale, -8 * scale)
      ..lineTo(30 * scale, 0)
      ..lineTo(25 * scale, 8 * scale)
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);

    arrowStroke
      ..strokeWidth = 2 * scale
      ..color = const Color(0xFF666666);
    canvas.drawPath(arrowPath, arrowStroke);

    pointPaint.color = Colors.white;
    final pointPath = Path()
      ..moveTo(25 * scale, -5 * scale)
      ..lineTo(35 * scale, 0)
      ..lineTo(25 * scale, 5 * scale)
      ..close();

    canvas.drawPath(pointPath, pointPaint);
    canvas.drawPath(pointPath, arrowStroke);

    hookPaint
      ..color = const Color(0xFF888888)
      ..strokeWidth = 2 * scale;

    canvas.drawLine(Offset(20 * scale, -6 * scale), Offset(18 * scale, -12 * scale), hookPaint);
    canvas.drawLine(Offset(20 * scale, 6 * scale), Offset(18 * scale, 12 * scale), hookPaint);

    detailPaint
      ..color = const Color(0xFF555555)
      ..strokeWidth = 1 * scale;

    for (int i = 0; i < 3; i++) {
      final xPos = (5.0 + i * 7) * scale;
      canvas.drawLine(Offset(xPos, -3 * scale), Offset(xPos + 3 * scale, -6 * scale), detailPaint);
      canvas.drawLine(Offset(xPos, 3 * scale), Offset(xPos + 3 * scale, 6 * scale), detailPaint);
    }

    canvas.restore();
  }

  void drawSkull(Canvas canvas, Paint skullPaint, Paint skullStroke, Paint orbitPaint, 
                 Paint eyePaint, Paint jawPaint, Paint fangPaint, Paint fangStroke, 
                 Paint crackPaint) {
    final head = vertebrae[0];

    canvas.save();
    canvas.translate(head.position.dx, head.position.dy);
    canvas.rotate(head.angle);

    skullPaint.color = const Color(0xFFE8E8E8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(25 * scale, 0), width: 70 * scale, height: 40 * scale),
      skullPaint,
    );

    skullStroke
      ..strokeWidth = 2 * scale
      ..color = const Color(0xFF666666);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(25 * scale, 0), width: 70 * scale, height: 40 * scale),
      skullStroke,
    );

    final snoutPath = Path()
      ..moveTo(60 * scale, 0)
      ..lineTo(80 * scale, -3 * scale)
      ..lineTo(80 * scale, 3 * scale)
      ..close();

    canvas.drawPath(snoutPath, skullPaint);
    canvas.drawPath(snoutPath, skullStroke);

    orbitPaint.color = Colors.black;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(35 * scale, -12 * scale), width: 20 * scale, height: 24 * scale),
      orbitPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(35 * scale, 12 * scale), width: 20 * scale, height: 24 * scale),
      orbitPaint,
    );

    eyePaint.color = const Color(0xFFFF0000);
    canvas.drawCircle(Offset(35 * scale, -12 * scale), 5 * scale, eyePaint);
    canvas.drawCircle(Offset(35 * scale, 12 * scale), 5 * scale, eyePaint);

    final jawPath = Path()
      ..moveTo(-10 * scale, 0)
      ..lineTo(60 * scale, -10 * scale)
      ..lineTo(78 * scale, 0)
      ..lineTo(60 * scale, 10 * scale)
      ..close();

    jawPaint.color = const Color(0xFFD8D8D8);
    canvas.drawPath(jawPath, jawPaint);
    canvas.drawPath(jawPath, skullStroke);

    fangPaint.color = Colors.white;
    fangStroke
      ..color = const Color(0xFF444444)
      ..strokeWidth = 1 * scale;

    for (int i = 0; i < 2; i++) {
      final x = (55.0 + i * 15) * scale;
      final topFang = Path()
        ..moveTo(x, -8 * scale)
        ..lineTo(x - 3 * scale, -18 * scale)
        ..lineTo(x + 3 * scale, -18 * scale)
        ..close();

      canvas.drawPath(topFang, fangPaint);
      canvas.drawPath(topFang, fangStroke);

      final bottomFang = Path()
        ..moveTo(x, 8 * scale)
        ..lineTo(x - 3 * scale, 18 * scale)
        ..lineTo(x + 3 * scale, 18 * scale)
        ..close();

      canvas.drawPath(bottomFang, fangPaint);
      canvas.drawPath(bottomFang, fangStroke);
    }

    for (int i = 0; i < 3; i++) {
      final x = (48.0 + i * 6) * scale;
      final topTooth = Path()
        ..moveTo(x, -6 * scale)
        ..lineTo(x - 1.5 * scale, -11 * scale)
        ..lineTo(x + 1.5 * scale, -11 * scale)
        ..close();

      canvas.drawPath(topTooth, fangPaint);
      canvas.drawPath(topTooth, fangStroke);

      final bottomTooth = Path()
        ..moveTo(x, 6 * scale)
        ..lineTo(x - 1.5 * scale, 11 * scale)
        ..lineTo(x + 1.5 * scale, 11 * scale)
        ..close();

      canvas.drawPath(bottomTooth, fangPaint);
      canvas.drawPath(bottomTooth, fangStroke);
    }

    crackPaint
      ..color = const Color(0xFF555555)
      ..strokeWidth = 1.5 * scale;

    canvas.drawLine(Offset(10 * scale, -18 * scale), Offset(45 * scale, -18 * scale), crackPaint);
    canvas.drawLine(Offset(10 * scale, 18 * scale), Offset(45 * scale, 18 * scale), crackPaint);
    canvas.drawLine(Offset(20 * scale, 0), Offset(15 * scale, -10 * scale), crackPaint);

    canvas.restore();
  }
}
class SkeletonPainter extends CustomPainter {
  final SnakeSkeleton snake;
  
  static final _connectionPaint = Paint()
    ..color = const Color(0xFF555555)
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;
    
  static final _bodyPaint = Paint()
    ..style = PaintingStyle.fill;
    
  static final _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
    
  static final _canalPaint = Paint();
  static final _transversePaint = Paint();
  static final _legPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
    
  static final _jointPaint = Paint()
    ..style = PaintingStyle.fill;
    
  static final _clawPaint = Paint()
    ..strokeCap = StrokeCap.round;
    
  static final _segPaint = Paint()
    ..strokeCap = StrokeCap.round;
    
  static final _bonePaint = Paint();
  static final _arrowPaint = Paint()
    ..style = PaintingStyle.fill;
    
  static final _arrowStroke = Paint()
    ..style = PaintingStyle.stroke;
    
  static final _pointPaint = Paint();
  static final _hookPaint = Paint()
    ..strokeCap = StrokeCap.round;
    
  static final _detailPaint = Paint();
  static final _skullPaint = Paint();
  static final _skullStroke = Paint()
    ..style = PaintingStyle.stroke;
    
  static final _orbitPaint = Paint();
  static final _eyePaint = Paint();
  static final _jawPaint = Paint();
  static final _fangPaint = Paint();
  static final _fangStroke = Paint()
    ..style = PaintingStyle.stroke;
    
  static final _crackPaint = Paint()
    ..strokeCap = StrokeCap.round;

  SkeletonPainter(this.snake);

  @override
  void paint(Canvas canvas, Size size) {
    _connectionPaint.strokeWidth = 4 * snake.scale;
    for (int i = 0; i < snake.vertebrae.length - 1; i++) {
      final v1 = snake.vertebrae[i];
      final v2 = snake.vertebrae[i + 1];
      canvas.drawLine(v1.position, v2.position, _connectionPaint);
    }

    for (int i = snake.vertebrae.length - 1; i >= 0; i--) {
      snake.vertebrae[i].draw(
        canvas, 
        snake.walkPhase, 
        _bodyPaint, 
        _strokePaint, 
        _canalPaint, 
        _transversePaint,
        _legPaint,
        _jointPaint,
        _clawPaint
      );
    }

    snake.drawTail(canvas, _segPaint, _bonePaint, _arrowPaint, _arrowStroke, 
                   _pointPaint, _hookPaint, _detailPaint);
    snake.drawSkull(canvas, _skullPaint, _skullStroke, _orbitPaint, _eyePaint, 
                    _jawPaint, _fangPaint, _fangStroke, _crackPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}