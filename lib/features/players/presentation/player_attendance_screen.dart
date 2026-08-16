import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/player_attendance_stats.dart';
import '../models/player_model.dart';
import '../repositories/player_repository.dart';

class PlayerAttendanceScreen extends StatefulWidget {
  const PlayerAttendanceScreen({required this.player, super.key});

  final PlayerModel player;

  @override
  State<PlayerAttendanceScreen> createState() => _PlayerAttendanceScreenState();
}

class _PlayerAttendanceScreenState extends State<PlayerAttendanceScreen> {
  final PlayerRepository _repository = const PlayerRepository();

  PlayerAttendanceStats _stats = PlayerAttendanceStats.empty();

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final PlayerAttendanceStats stats = await _repository
          .getPlayerAttendanceStats(widget.player.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'No fue posible cargar las estadísticas de asistencia.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Asistencia del jugador',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadStats,
            tooltip: 'Actualizar estadísticas',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.fuchsia,
          onRefresh: _loadStats,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isLoading)
                        const LinearProgressIndicator(
                          minHeight: 3,
                          color: AppColors.yellow,
                          backgroundColor: Color(0xFFE6D3DE),
                        ),
                      if (_isLoading) const SizedBox(height: 14),
                      if (_errorMessage != null)
                        _ErrorCard(
                          message: _errorMessage!,
                          onRetry: _loadStats,
                        ),
                      if (_errorMessage != null) const SizedBox(height: 16),
                      _PlayerBanner(player: widget.player),
                      const SizedBox(height: 18),
                      _AttendanceHero(stats: _stats),
                      const SizedBox(height: 18),
                      _StatisticsGrid(stats: _stats),
                      const SizedBox(height: 18),
                      _LastAttendanceCard(stats: _stats),
                      const SizedBox(height: 18),
                      _AttendanceInterpretation(stats: _stats),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text(
                            'VOLVER A LA FICHA',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.fuchsia,
                            side: const BorderSide(color: AppColors.fuchsia),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerBanner extends StatelessWidget {
  const _PlayerBanner({required this.player});

  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia, Color(0xFF8B004D)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.fuchsia.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 3),
            ),
            child: Center(
              child: Text(
                player.initials.isEmpty ? '?' : player.initials,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.fullName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Código: ${player.playerCode}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  player.displayTrainingGroup,
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceHero extends StatelessWidget {
  const _AttendanceHero({required this.stats});

  final PlayerAttendanceStats stats;

  @override
  Widget build(BuildContext context) {
    final double percentage = stats.attendancePercentage
        .clamp(0, 100)
        .toDouble();

    final Color color = _attendanceColor(percentage);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 570;

          final Widget percentageWidget = _PercentageIndicator(
            percentage: percentage,
            displayPercentage: stats.displayPercentage,
            color: color,
          );

          final Widget description = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                stats.hasAttendance
                    ? 'Asistencia general'
                    : 'Todavía no hay registros',
                textAlign: compact ? TextAlign.center : null,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                stats.hasAttendance
                    ? 'Porcentaje calculado con los entrenamientos registrados.'
                    : 'La información aparecerá después de guardar la primera asistencia.',
                textAlign: compact ? TextAlign.center : null,
                style: const TextStyle(
                  color: Color(0xFF756970),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  minHeight: 12,
                  value: percentage / 100,
                  backgroundColor: color.withValues(alpha: 0.12),
                  color: color,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                '${stats.attendedCount} asistencias efectivas de '
                '${stats.totalSessions} entrenamientos',
                textAlign: compact ? TextAlign.center : null,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [
                percentageWidget,
                const SizedBox(height: 20),
                description,
              ],
            );
          }

          return Row(
            children: [
              percentageWidget,
              const SizedBox(width: 24),
              Expanded(child: description),
            ],
          );
        },
      ),
    );
  }

  static Color _attendanceColor(double percentage) {
    if (percentage >= 90) {
      return const Color(0xFF168A55);
    }

    if (percentage >= 75) {
      return const Color(0xFFF9A825);
    }

    return const Color(0xFFC62828);
  }
}

class _PercentageIndicator extends StatelessWidget {
  const _PercentageIndicator({
    required this.percentage,
    required this.displayPercentage,
    required this.color,
  });

  final double percentage;
  final String displayPercentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 136,
            height: 136,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 12,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayPercentage,
                style: TextStyle(
                  color: color,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'ASISTENCIA',
                style: TextStyle(
                  color: Color(0xFF756970),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({required this.stats});

  final PlayerAttendanceStats stats;

  @override
  Widget build(BuildContext context) {
    final List<_AttendanceStatisticData> items = <_AttendanceStatisticData>[
      _AttendanceStatisticData(
        label: 'Entrenamientos',
        value: stats.totalSessions,
        icon: Icons.sports_soccer_rounded,
        color: AppColors.fuchsia,
      ),
      _AttendanceStatisticData(
        label: 'Presentes',
        value: stats.presentCount,
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF168A55),
      ),
      _AttendanceStatisticData(
        label: 'Tardanzas',
        value: stats.lateCount,
        icon: Icons.schedule_rounded,
        color: const Color(0xFFF9A825),
      ),
      _AttendanceStatisticData(
        label: 'Ausencias',
        value: stats.absentCount,
        icon: Icons.cancel_rounded,
        color: const Color(0xFFC62828),
      ),
      _AttendanceStatisticData(
        label: 'Lesionado',
        value: stats.injuredCount,
        icon: Icons.healing_rounded,
        color: const Color(0xFF6A1B9A),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 760
            ? 5
            : constraints.maxWidth >= 500
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (BuildContext context, int index) {
            return _AttendanceStatisticCard(data: items[index]);
          },
        );
      },
    );
  }
}

class _AttendanceStatisticCard extends StatelessWidget {
  const _AttendanceStatisticCard({required this.data});

  final _AttendanceStatisticData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: data.color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.value}',
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF756970),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LastAttendanceCard extends StatelessWidget {
  const _LastAttendanceCard({required this.stats});

  final PlayerAttendanceStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.11)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.fuchsia.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: AppColors.fuchsia,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Último registro',
                  style: TextStyle(
                    color: Color(0xFF81747A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Última asistencia guardada',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            stats.displayLastAttendance,
            style: const TextStyle(
              color: AppColors.fuchsia,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceInterpretation extends StatelessWidget {
  const _AttendanceInterpretation({required this.stats});

  final PlayerAttendanceStats stats;

  @override
  Widget build(BuildContext context) {
    final _AttendanceMessage message = _AttendanceMessage.fromStats(stats);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: message.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: message.color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(message.icon, color: message.color, size: 31),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.title,
                  style: TextStyle(
                    color: message.color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message.description,
                  style: const TextStyle(
                    color: Color(0xFF5F555A),
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8A2525),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('REINTENTAR')),
        ],
      ),
    );
  }
}

class _AttendanceMessage {
  const _AttendanceMessage({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });

  final String title;
  final String description;
  final Color color;
  final IconData icon;

  factory _AttendanceMessage.fromStats(PlayerAttendanceStats stats) {
    if (!stats.hasAttendance) {
      return const _AttendanceMessage(
        title: 'Sin historial todavía',
        description:
            'Registra las asistencias del jugador para comenzar a construir su historial de compromiso y puntualidad.',
        color: Color(0xFF777777),
        icon: Icons.info_outline_rounded,
      );
    }

    final double percentage = stats.attendancePercentage;

    if (percentage >= 90) {
      return const _AttendanceMessage(
        title: 'Excelente compromiso',
        description:
            'El jugador mantiene un nivel sobresaliente de asistencia y participación en los entrenamientos.',
        color: Color(0xFF168A55),
        icon: Icons.workspace_premium_rounded,
      );
    }

    if (percentage >= 75) {
      return const _AttendanceMessage(
        title: 'Buen nivel de asistencia',
        description:
            'El jugador presenta una asistencia favorable. Conviene mantener la constancia para fortalecer su proceso formativo.',
        color: Color(0xFFF9A825),
        icon: Icons.trending_up_rounded,
      );
    }

    return const _AttendanceMessage(
      title: 'Asistencia por mejorar',
      description:
          'La frecuencia de participación necesita seguimiento para evitar interrupciones en el proceso formativo del jugador.',
      color: Color(0xFFC62828),
      icon: Icons.priority_high_rounded,
    );
  }
}

class _AttendanceStatisticData {
  const _AttendanceStatisticData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}
