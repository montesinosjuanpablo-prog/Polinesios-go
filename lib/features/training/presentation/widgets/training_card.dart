import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../models/training_session_model.dart';

class TrainingCard extends StatelessWidget {
  const TrainingCard({
    required this.session,
    required this.onPressed,
    super.key,
  });

  final TrainingSessionModel session;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final _StatusStyle statusStyle = _StatusStyle.fromStatus(session.status);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.fuchsia.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.fuchsia.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.sports_soccer_rounded,
                      color: AppColors.fuchsia,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.categoryName.isEmpty
                              ? 'Entrenamiento'
                              : session.categoryName,
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(session.date),
                          style: const TextStyle(
                            color: Color(0xFF786C72),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusStyle.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusStyle.icon,
                          size: 15,
                          color: statusStyle.color,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusStyle.label,
                          style: TextStyle(
                            color: statusStyle.color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              const Divider(height: 1),
              const SizedBox(height: 15),
              Wrap(
                spacing: 18,
                runSpacing: 12,
                children: [
                  _InformationItem(
                    icon: Icons.schedule_rounded,
                    text:
                        '${_shortTime(session.startTime)} - ${_shortTime(session.endTime)}',
                  ),
                  _InformationItem(
                    icon: Icons.location_on_outlined,
                    text: session.location.isEmpty
                        ? 'Lugar no registrado'
                        : session.location,
                  ),
                  _InformationItem(
                    icon: Icons.person_outline_rounded,
                    text: session.coachName.isEmpty
                        ? 'Entrenador no registrado'
                        : session.coachName,
                  ),
                ],
              ),
              if (session.objective.trim().isNotEmpty) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F3F5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        color: AppColors.fuchsia,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          session.objective,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF594E53),
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const List<String> months = <String>[
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  static String _shortTime(String time) {
    if (time.length >= 5) {
      return time.substring(0, 5);
    }

    return time;
  }
}

class _InformationItem extends StatelessWidget {
  const _InformationItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.fuchsia),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF665A60),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  factory _StatusStyle.fromStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
        return const _StatusStyle(
          label: 'COMPLETADO',
          color: Color(0xFF168A55),
          background: Color(0xFFE3F5EC),
          icon: Icons.check_circle_rounded,
        );

      case 'cancelled':
        return const _StatusStyle(
          label: 'CANCELADO',
          color: Color(0xFFC62828),
          background: Color(0xFFFFE5E5),
          icon: Icons.cancel_rounded,
        );

      default:
        return const _StatusStyle(
          label: 'PROGRAMADO',
          color: Color(0xFFD97706),
          background: Color(0xFFFFF3D6),
          icon: Icons.schedule_rounded,
        );
    }
  }
}
