import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GaugeCard extends StatefulWidget {
  final String label;
  final double value;   // 0.0 – 1.0
  final String valueText;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;

  const GaugeCard({
    super.key,
    required this.label,
    required this.value,
    required this.valueText,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
  });

  @override
  State<GaugeCard> createState() => _GaugeCardState();
}

class _GaugeCardState extends State<GaugeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(GaugeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = _animation.value;
      _animation = Tween<double>(begin: _previousValue, end: widget.value)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(120, 120),
                painter: _GaugePainter(
                  value: _animation.value,
                  primaryColor: widget.primaryColor,
                  secondaryColor: widget.secondaryColor,
                  icon: widget.icon,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            widget.valueText,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: widget.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;

  _GaugePainter({
    required this.value,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = math.pi * 0.75;
    const fullSweep = math.pi * 1.5;

    // Background arc
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.08);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep,
      false,
      bgPaint,
    );

    // Foreground arc with gradient
    final sweepAngle = fullSweep * value.clamp(0.0, 1.0);
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [primaryColor, secondaryColor],
        startAngle: startAngle,
        endAngle: startAngle + fullSweep,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );

    // Center glow dot
    final c = value.clamp(0.0, 1.0);
    final glowAngle = startAngle + fullSweep * c;
    final dotX = center.dx + radius * math.cos(glowAngle);
    final dotY = center.dy + radius * math.sin(glowAngle);

    final glowPaint = Paint()
      ..color = Color.lerp(primaryColor, secondaryColor, c)!.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(dotX, dotY), 7, glowPaint);

    final dotPaint = Paint()
      ..color = Color.lerp(primaryColor, secondaryColor, c)!;
    canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.value != value;
}
