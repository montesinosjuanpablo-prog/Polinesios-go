import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class IdentityPolinesiosScreen extends StatelessWidget {
  const IdentityPolinesiosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        title: const Text(
          'Identidad Polinesios',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
          child: Column(
            children: [
              const _IdentityCard(
                icon: Icons.hive_rounded,
                customIcon: _SimpleBeeMark(
                  color: AppColors.fuchsia,
                  facingRight: true,
                  size: 30,
                ),
                title: 'NUESTRA ABEJA',
                child: Text(
                  'Representa trabajo en equipo, esfuerzo, perseverancia. '
                  'Las abejas traen prosperidad, sabiduría, abundancia '
                  'y dulzura a la vida.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF675B61),
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const _IdentityCard(
                icon: Icons.palette_rounded,
                title: 'NUESTROS COLORES',
                child: Column(
                  children: [
                    _ColorMeaning(
                      heartColor: AppColors.fuchsia,
                      name: 'Fucsia',
                      meaning: 'ENERGÍA, PASIÓN',
                    ),
                    SizedBox(height: 14),
                    _ColorMeaning(
                      heartColor: AppColors.yellow,
                      name: 'Amarillo',
                      meaning: 'ALEGRÍA, OPTIMISMO, LUZ',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _IdentityCard(
                icon: Icons.flag_rounded,
                title: 'NUESTRA MISIÓN',
                child: Column(
                  children: [
                    Text(
                      'Formar y Enseñar a nuestros niños, niñas y jóvenes '
                      'teniendo como base estos 3 pilares:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF675B61),
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 18),
                    _MissionPillar(text: 'Nunca dejes de Soñar'),
                    SizedBox(height: 10),
                    _MissionPillar(text: 'Nunca dejes de Intentar'),
                    SizedBox(height: 10),
                    _MissionPillar(text: 'Nunca te Rindas'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppColors.darkFuchsia, AppColors.fuchsia],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_rounded, color: AppColors.yellow),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'VIVIMOS POLINESIOS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.icon,
    required this.title,
    required this.child,
    this.customIcon,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? customIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(15),
            ),
            child:
                customIcon ??
                Icon(icon, color: AppColors.darkFuchsia, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ColorMeaning extends StatelessWidget {
  const _ColorMeaning({
    required this.heartColor,
    required this.name,
    required this.meaning,
  });

  final Color heartColor;
  final String name;
  final String meaning;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.favorite_rounded, color: heartColor, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Text(
                '$name:',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meaning,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF675B61),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.favorite_rounded, color: heartColor, size: 28),
      ],
    );
  }
}

class _SimpleBeeMark extends StatelessWidget {
  const _SimpleBeeMark({
    required this.color,
    required this.facingRight,
    required this.size,
  });

  final Color color;
  final bool facingRight;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SimpleBeePainter(color: color, facingRight: facingRight),
      ),
    );
  }
}

class _SimpleBeePainter extends CustomPainter {
  const _SimpleBeePainter({required this.color, required this.facingRight});

  final Color color;
  final bool facingRight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    if (!facingRight) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final double w = size.width;
    final double h = size.height;

    final Color detailColor = color == AppColors.yellow
        ? const Color(0xFF3E3036)
        : AppColors.darkFuchsia;

    final Paint bodyPaint = Paint()..color = color;
    final Paint detailPaint = Paint()
      ..color = detailColor
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;
    final Paint wingPaint = Paint()
      ..color = color.withValues(alpha: 0.17)
      ..style = PaintingStyle.fill;
    final Paint wingStroke = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;

    // Alas simples: silueta limpia tipo logo.
    final Rect upperWing = Rect.fromCenter(
      center: Offset(w * 0.38, h * 0.29),
      width: w * 0.34,
      height: h * 0.28,
    );
    final Rect lowerWing = Rect.fromCenter(
      center: Offset(w * 0.38, h * 0.64),
      width: w * 0.32,
      height: h * 0.24,
    );
    canvas.drawOval(upperWing, wingPaint);
    canvas.drawOval(upperWing, wingStroke);
    canvas.drawOval(lowerWing, wingPaint);
    canvas.drawOval(lowerWing, wingStroke);

    // Cuerpo horizontal y cabeza.
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.27, h * 0.36, w * 0.47, h * 0.34),
      Radius.circular(h * 0.17),
    );
    canvas.drawRRect(body, bodyPaint);

    canvas.drawCircle(Offset(w * 0.73, h * 0.52), w * 0.16, bodyPaint);

    // Dos franjas, suficientes para que se lea inmediatamente como abeja.
    canvas.drawLine(
      Offset(w * 0.42, h * 0.39),
      Offset(w * 0.42, h * 0.67),
      detailPaint,
    );
    canvas.drawLine(
      Offset(w * 0.56, h * 0.38),
      Offset(w * 0.56, h * 0.68),
      detailPaint,
    );

    // Aguijón discreto.
    final Path sting = Path()
      ..moveTo(w * 0.25, h * 0.47)
      ..lineTo(w * 0.10, h * 0.53)
      ..lineTo(w * 0.25, h * 0.59)
      ..close();
    canvas.drawPath(sting, bodyPaint);

    // Ojo.
    canvas.drawCircle(
      Offset(w * 0.79, h * 0.48),
      w * 0.025,
      Paint()..color = detailColor,
    );

    // Antenas.
    canvas.drawLine(
      Offset(w * 0.77, h * 0.38),
      Offset(w * 0.82, h * 0.25),
      detailPaint,
    );
    canvas.drawLine(
      Offset(w * 0.84, h * 0.40),
      Offset(w * 0.91, h * 0.29),
      detailPaint,
    );
    canvas.drawCircle(
      Offset(w * 0.82, h * 0.25),
      w * 0.025,
      Paint()..color = detailColor,
    );
    canvas.drawCircle(
      Offset(w * 0.91, h * 0.29),
      w * 0.025,
      Paint()..color = detailColor,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SimpleBeePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.facingRight != facingRight;
  }
}

class _MissionPillar extends StatelessWidget {
  const _MissionPillar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.fuchsia,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
