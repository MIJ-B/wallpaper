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
  List<Food> _foods = [];
  bool _isGameOver = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(() {
      if (!_isGameOver) {
        setState(() {
          if (!_isDragging) {
            _time += 0.01;
          }
          _checkCollisions();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    _dragPosition = Offset(size.width / 2, size.height / 2);
    _lastDragPosition = _dragPosition;
    _snake = SnakeSkeleton(25, _dragPosition);
    _spawnFood(size);
  }

  void _spawnFood(Size size) {
    final random = math.Random();
    _foods = List.generate(5, (index) {
      return Food(
        position: Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
      );
    });
  }

  void _checkCollisions() {
    final size = MediaQuery.of(context).size;
    final head = _snake.vertebrae[0].position;

    // Check food collision
    for (int i = _foods.length - 1; i >= 0; i--) {
      final food = _foods[i];
      final distance = (head - food.position).distance;
      
      if (distance < 30) {
        setState(() {
          _foods.removeAt(i);
          _snake.grow();
          _score++;
          
          // Spawn new food
          final random = math.Random();
          _foods.add(Food(
            position: Offset(
              random.nextDouble() * size.width,
              random.nextDouble() * size.height,
            ),
          ));
        });
      }
    }

    // Check self collision (skip first few vertebrae)
    for (int i = 5; i < _snake.vertebrae.length; i++) {
      final distance = (head - _snake.vertebrae[i].position).distance;
      if (distance < 15) {
        setState(() {
          _isGameOver = true;
        });
        break;
      }
    }
  }

  void _restartGame() {
    final size = MediaQuery.of(context).size;
    setState(() {
      _isGameOver = false;
      _score = 0;
      _time = 0;
      _dragPosition = Offset(size.width / 2, size.height / 2);
      _lastDragPosition = _dragPosition;
      _snake = SnakeSkeleton(25, _dragPosition);
      _spawnFood(size);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _getAutoPosition(Size size) {
    final pattern = (_time / 10).floor() % 4;

    switch (pattern) {
      case 0:
        return Offset(
          _lastDragPosition.dx + math.sin(_time) * 200,
          _lastDragPosition.dy + math.sin(_time * 2) * 150,
        );
      case 1:
        return Offset(
          _lastDragPosition.dx + math.sin(_time * 1.5) * 250,
          _lastDragPosition.dy + math.cos(_time * 0.8) * 100,
        );
      case 2:
        final radius = 100 + math.sin(_time * 0.5) * 80;
        return Offset(
          _lastDragPosition.dx + math.cos(_time * 2) * radius,
          _lastDragPosition.dy + math.sin(_time * 2) * radius,
        );
      case 3:
        return Offset(
          _lastDragPosition.dx + math.sin(_time * 2) * 200,
          _lastDragPosition.dy + math.sin(_time * 3) * 120,
        );
      default:
        return _lastDragPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final targetPosition = _isDragging ? _dragPosition : _getAutoPosition(size);

    if (!_isGameOver) {
      _snake.update(targetPosition);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              if (!_isGameOver) {
                setState(() {
                  _isDragging = true;
                  _dragPosition = details.localPosition;
                  _lastDragPosition = _dragPosition;
                });
              }
            },
            onPanUpdate: (details) {
              if (!_isGameOver) {
                setState(() {
                  _dragPosition = details.localPosition;
                  _lastDragPosition = _dragPosition;
                });
              }
            },
            onPanEnd: (details) {
              if (!_isGameOver) {
                setState(() {
                  _isDragging = false;
                  _time = 0;
                });
              }
            },
            child: CustomPaint(
              size: size,
              painter: SkeletonPainter(_snake, _foods),
            ),
          ),
          // Score display
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Score: $_score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Game Over overlay
          if (_isGameOver)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sentiment_dissatisfied,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Final Score: $_score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _restartGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                      ),
                      child: const Text(
                        'RESTART',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Food {
  final Offset position;
  
  Food({required this.position});

  void draw(Canvas canvas) {
    // Glow effect
    final glowPaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(position, 20, glowPaint);

    // Outer circle
    final outerPaint = Paint()
      ..color = const Color(0xFF00FF00)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 12, outerPaint);

    // Inner circle
    final innerPaint = Paint()
      ..color = const Color(0xFF88FF88)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 8, innerPaint);

    // Center dot
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 3, centerPaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF00AA00)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(position, 12, borderPaint);
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
  int total;
  final List<Leg> legs = [];

  Vertebra({
    required this.position,
    required this.size,
    required this.angle,
    required this.index,
    required this.total,
  }) {
    _updateLegs();
  }

  void _updateLegs() {
    legs.clear();
    if (index >= 2 && index < total - 3) {
      legs.add(Leg('left', index, total));
      legs.add(Leg('right', index, total));
    }
  }

  void updateTotal(int newTotal) {
    total = newTotal;
    _updateLegs();
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
  int numVertebrae;
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

  void grow() {
    final lastVert = vertebrae.last;
    final prevVert = vertebrae[vertebrae.length - 2];
    
    final angle = math.atan2(
      lastVert.position.dy - prevVert.position.dy,
      lastVert.position.dx - prevVert.position.dx,
    );
    
    // Add 3 new segments when eating
    for (int i = 0; i < 3; i++) {
      numVertebrae++;
      final size = baseSize * (1 - (numVertebrae / (numVertebrae + 1)) * 0.5);
      final spacing = size * 0.8;
      
      vertebrae.add(Vertebra(
        position: Offset(
          lastVert.position.dx + math.cos(angle) * spacing * (i + 1),
          lastVert.position.dy + math.sin(angle) * spacing * (i + 1),
        ),
        size: size,
        angle: angle,
        index: vertebrae.length,
        total: numVertebrae,
      ));
    }
    
    // Update total count for all vertebrae
    for (var vert in vertebrae) {
      vert.updateTotal(numVertebrae);
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

class SkeletonPainter extends CustomPainter {
  final SnakeSkeleton snake;
  final List<Food> foods;

  SkeletonPainter(this.snake, this.foods);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw food first
    for (var food in foods) {
      food.draw(canvas);
    }

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