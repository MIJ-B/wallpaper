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
    
    // Draw stars background
    _drawStars(canvas, size);
    
    // Draw 3D globe (similar to Three.js)
    _draw3DGlobe(canvas, center, size);
    
    // Draw orbiting particles
    _drawOrbitingParticles(canvas, center, size);
  }

  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white;
    final random = math.Random(42);
    
    for (int i = 0; i < 300; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final starSize = random.nextDouble() * 2.5 + 0.3;
      
      // Twinkling effect
      final twinkle = math.sin(rotation * 8 + i * 0.5) * 0.5 + 0.5;
      final brightness = random.nextDouble() * 0.5 + 0.5;
      starPaint.color = Colors.white.withOpacity(twinkle * brightness);
      
      canvas.drawCircle(Offset(x, y), starSize, starPaint);
      
      // Some stars with glow
      if (random.nextDouble() > 0.9) {
        final glowPaint = Paint()
          ..color = Colors.white.withOpacity(twinkle * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(x, y), starSize * 2, glowPaint);
      }
    }
  }

  void _draw3DGlobe(Canvas canvas, Offset center, Size size) {
    final globeRadius = (math.min(size.width, size.height) * 0.35) * zoom;
    
    // 1. Draw sphere shadow/depth
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.5),
        ],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: globeRadius));
    
    canvas.drawCircle(center, globeRadius, shadowPaint);
    
    // 2. Draw main sphere with gradient (like Three.js MeshPhongMaterial)
    final sphereGradient = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          const Color(0xFF1a3a5c).withOpacity(0.3),
          const Color(0xFF0d1f35).withOpacity(0.2),
          Colors.black.withOpacity(0.1),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: globeRadius));
    
    canvas.drawCircle(center, globeRadius, sphereGradient);
    
    // 3. Draw latitude lines (parallels)
    final latitudePaint = Paint()
      ..color = const Color(0xFF4a90e2).withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    for (int i = 1; i < 9; i++) {
      final lat = (i / 9) * math.pi - math.pi / 2;
      final y = center.dy - (globeRadius * math.sin(lat));
      final ringRadius = globeRadius * math.cos(lat);
      
      if (ringRadius > 0) {
        // 3D perspective effect
        final perspectiveScale = 0.25; // Flattening effect
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx, y),
            width: ringRadius * 2,
            height: ringRadius * 2 * perspectiveScale,
          ),
          latitudePaint,
        );
      }
    }
    
    // 4. Draw longitude lines (meridians) with rotation
    final longitudePaint = Paint()
      ..color = const Color(0xFF4a90e2).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 16; i++) {
      final lonAngle = (i / 16) * math.pi * 2 + rotation;
      final path = Path();
      
      bool started = false;
      for (double t = -math.pi / 2; t <= math.pi / 2; t += 0.05) {
        // 3D sphere coordinates
        final x = globeRadius * math.cos(t) * math.sin(lonAngle);
        final y = globeRadius * math.sin(t);
        final z = globeRadius * math.cos(t) * math.cos(lonAngle);
        
        // Only draw front-facing parts (z >= 0)
        if (z >= 0) {
          final projectedX = center.dx + x;
          final projectedY = center.dy - y;
          
          // Fade based on depth (z-axis)
          final depth = z / globeRadius;
          
          if (!started) {
            path.moveTo(projectedX, projectedY);
            started = true;
          } else {
            path.lineTo(projectedX, projectedY);
          }
        } else {
          started = false;
        }
      }
      
      canvas.drawPath(path, longitudePaint);
    }
    
    // 5. Draw equator (highlighted)
    final equatorPaint = Paint()
      ..color = const Color(0xFF64b5f6).withOpacity(0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: globeRadius * 2,
        height: globeRadius * 2 * 0.25,
      ),
      equatorPaint,
    );
    
    // 6. Draw continental outlines (simplified)
    _drawContinents(canvas, center, globeRadius);
    
    // 7. Outer glow/atmosphere
    final atmospherePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF2196f3).withOpacity(0.3),
          const Color(0xFF64b5f6).withOpacity(0.1),
        ],
        stops: const [0.92, 0.96, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: globeRadius * 1.08));
    
    canvas.drawCircle(center, globeRadius * 1.08, atmospherePaint);
    
    // 8. Highlight/specular light (Three.js style)
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4],
      ).createShader(Rect.fromCircle(center: center, radius: globeRadius * 0.3));
    
    canvas.drawCircle(
      Offset(center.dx - globeRadius * 0.3, center.dy - globeRadius * 0.3),
      globeRadius * 0.3,
      highlightPaint,
    );
  }

  void _drawContinents(Canvas canvas, Offset center, double radius) {
    final continentPaint = Paint()
      ..color = const Color(0xFF81c784).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final continentStroke = Paint()
      ..color = const Color(0xFF66bb6a).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Simplified continent shapes (Africa-like, Americas-like)
    // Africa region
    final africaPath = Path();
    for (double t = 0; t < math.pi * 2; t += 0.2) {
      final angle = t + rotation * 0.5;
      final lat = math.sin(t * 2) * 0.4;
      
      final x = radius * 0.9 * math.cos(lat) * math.sin(angle);
      final y = radius * 0.9 * math.sin(lat);
      final z = radius * 0.9 * math.cos(lat) * math.cos(angle);
      
      if (z >= 0 && angle > math.pi * 0.3 && angle < math.pi * 0.7) {
        final projX = center.dx + x;
        final projY = center.dy - y;
        
        if (t == 0 || africaPath.getBounds().isEmpty) {
          africaPath.moveTo(projX, projY);
        } else {
          africaPath.lineTo(projX, projY);
        }
      }
    }
    
    canvas.drawPath(africaPath, continentPaint);
    canvas.drawPath(africaPath, continentStroke);
    
    // Americas region
    final americasPath = Path();
    for (double t = 0; t < math.pi * 2; t += 0.2) {
      final angle = t + rotation * 0.5 + math.pi;
      final lat = math.sin(t * 1.5) * 0.5;
      
      final x = radius * 0.85 * math.cos(lat) * math.sin(angle);
      final y = radius * 0.85 * math.sin(lat);
      final z = radius * 0.85 * math.cos(lat) * math.cos(angle);
      
      if (z >= 0 && angle > math.pi * 1.3 && angle < math.pi * 1.7) {
        final projX = center.dx + x;
        final projY = center.dy - y;
        
        if (t == 0 || americasPath.getBounds().isEmpty) {
          americasPath.moveTo(projX, projY);
        } else {
          americasPath.lineTo(projX, projY);
        }
      }
    }
    
    canvas.drawPath(americasPath, continentPaint);
    canvas.drawPath(americasPath, continentStroke);
  }

  void _drawOrbitingParticles(Canvas canvas, Offset center, Size size) {
    final globeRadius = (math.min(size.width, size.height) * 0.35) * zoom;
    final particlePaint = Paint()..style = PaintingStyle.fill;
    
    // Multiple orbit rings
    for (int ring = 0; ring < 3; ring++) {
      final orbitRadius = globeRadius * (1.15 + ring * 0.08);
      final particleCount = 20 + ring * 5;
      final speed = 1.5 + ring * 0.5;
      
      for (int i = 0; i < particleCount; i++) {
        final angle = (i / particleCount) * math.pi * 2 + rotation * speed;
        
        // 3D orbit
        final inclination = (ring - 1) * 0.3;
        final x = math.cos(angle) * orbitRadius;
        final y = math.sin(angle) * orbitRadius * math.cos(inclination);
        final z = math.sin(angle) * orbitRadius * math.sin(inclination);
        
        // Only draw particles in front
        if (z >= -orbitRadius * 0.5) {
          final px = center.dx + x;
          final py = center.dy + y;
          
          // Size based on depth
          final depth = (z + orbitRadius) / (orbitRadius * 2);
          final particleSize = (2.0 + ring * 0.5) * depth;
          
          // Color based on position and ring
          final hue = ((i / particleCount) * 360 + rotation * 30 + ring * 60) % 360;
          final opacity = 0.4 + depth * 0.4;
          particlePaint.color = HSVColor.fromAHSV(opacity, hue, 0.7, 1.0).toColor();
          
          canvas.drawCircle(Offset(px, py), particleSize, particlePaint);
          
          // Glow for brighter particles
          if (depth > 0.7) {
            final glowPaint = Paint()
              ..color = particlePaint.color.withOpacity(opacity * 0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
            canvas.drawCircle(Offset(px, py), particleSize * 2, glowPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpaceGlobePainter oldDelegate) {
    return rotation != oldDelegate.rotation || zoom != oldDelegate.zoom;
  }
}