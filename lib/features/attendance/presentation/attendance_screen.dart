import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/attendance_controller.dart';
import '../models/attendance_model.dart';
import '../repositories/attendance_repository.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final AttendanceController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AttendanceController();
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _selectGroup(String? groupId) async {
    if (groupId == null) {
      return;
    }

    await _controller.selectGroup(groupId);
  }

  Future<void> _saveAttendance() async {
    FocusScope.of(context).unfocus();

    final bool wasSaved = await _controller.saveAttendance();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: wasSaved
              ? const Color(0xFF168A55)
              : const Color(0xFFC62828),
          content: Row(
            children: [
              Icon(
                wasSaved ? Icons.check_circle_rounded : Icons.error_rounded,
                color: AppColors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  wasSaved
                      ? '¡Asistencia guardada correctamente!'
                      : _controller.errorMessage ??
                            'No fue posible guardar la asistencia.',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _selectPreviousDate() async {
    if (_controller.isBusy) {
      return;
    }

    final DateTime previousDate = _controller.sessionDate.subtract(
      const Duration(days: 1),
    );

    await _controller.selectSessionDate(previousDate);
  }

  Future<void> _selectNextDate() async {
    if (_controller.isBusy) {
      return;
    }

    final DateTime today = DateTime.now();

    final DateTime normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );

    if (!_controller.sessionDate.isBefore(normalizedToday)) {
      return;
    }

    final DateTime nextDate = _controller.sessionDate.add(
      const Duration(days: 1),
    );

    await _controller.selectSessionDate(nextDate);
  }

  Future<void> _openDatePicker() async {
    if (_controller.isBusy) {
      return;
    }

    final DateTime today = DateTime.now();

    final DateTime normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _controller.sessionDate,
      firstDate: DateTime(2024),
      lastDate: normalizedToday,
      helpText: 'Seleccionar fecha de asistencia',
      cancelText: 'CANCELAR',
      confirmText: 'SELECCIONAR',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    await _controller.selectSessionDate(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final AttendanceTrainingGroup? selectedGroup = _controller.selectedGroup;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Asistencia',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _controller.isBusy ? null : _controller.initialize,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: _controller.isLoadingGroups
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.fuchsia),
              )
            : RefreshIndicator(
                color: AppColors.fuchsia,
                onRefresh: _controller.initialize,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                  children: [
                    _AttendanceHeader(
                      selectedGroup: selectedGroup,
                      sessionDate: _controller.sessionDate,
                      onPreviousDate: _selectPreviousDate,
                      onNextDate: _selectNextDate,
                      onDatePressed: _openDatePicker,
                    ),
                    const SizedBox(height: 16),
                    if (_controller.errorMessage != null)
                      _ErrorCard(
                        message: _controller.errorMessage!,
                        onRetry: _controller.initialize,
                      ),
                    if (_controller.errorMessage != null)
                      const SizedBox(height: 16),
                    _GroupSelector(
                      groups: _controller.groups,
                      selectedGroup: _controller.selectedGroup,
                      onChanged: _selectGroup,
                    ),
                    const SizedBox(height: 16),
                    _AttendanceSummary(
                      total: _controller.totalPlayers,
                      present: _controller.presentCount,
                      late: _controller.lateCount,
                      absent: _controller.absentCount,
                      injured: _controller.injuredCount,
                    ),
                    const SizedBox(height: 16),
                    if (_controller.isLoadingPlayers)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.fuchsia,
                          ),
                        ),
                      )
                    else if (!_controller.hasPlayers)
                      const _EmptyAttendance()
                    else ...[
                      _ListHeader(
                        total: _controller.totalPlayers,
                        onMarkAllPresent: _controller.markAllPresent,
                      ),
                      const SizedBox(height: 10),
                      ..._controller.attendance.map((AttendanceModel item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AttendancePlayerCard(
                            attendance: item,
                            onTap: () {
                              _controller.cyclePlayerStatus(item.playerId);
                            },
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
      ),
      floatingActionButton: _controller.hasPlayers
          ? FloatingActionButton.extended(
              onPressed: _controller.isBusy
                  ? null
                  : () {
                      _saveAttendance();
                    },
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.black,
              icon: _controller.isSaving
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.black,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _controller.isSaving ? 'GUARDANDO...' : 'GUARDAR',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
    );
  }
}

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader({
    required this.selectedGroup,
    required this.sessionDate,
    required this.onPreviousDate,
    required this.onNextDate,
    required this.onDatePressed,
  });

  final AttendanceTrainingGroup? selectedGroup;
  final DateTime sessionDate;
  final VoidCallback onPreviousDate;
  final VoidCallback onNextDate;
  final VoidCallback onDatePressed;

  bool get _isToday {
    final DateTime now = DateTime.now();

    return sessionDate.year == now.year &&
        sessionDate.month == now.month &&
        sessionDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_rounded, color: AppColors.yellow, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Control de asistencia',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: onPreviousDate,
                tooltip: 'Día anterior',
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: onDatePressed,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.yellow,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _formatDate(sessionDate),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _isToday ? null : onNextDate,
                tooltip: _isToday ? 'Hoy' : 'Día siguiente',
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.white,
                  disabledForegroundColor: AppColors.white.withValues(
                    alpha: 0.35,
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(
                icon: Icons.groups_rounded,
                label: selectedGroup?.name ?? 'Selecciona un grupo',
              ),
              _HeaderChip(
                icon: Icons.location_on_rounded,
                label: selectedGroup?.displayLocation ?? 'Sin sede',
              ),
              _HeaderChip(
                icon: Icons.schedule_rounded,
                label: selectedGroup?.displaySchedule ?? 'Sin horario',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const List<String> weekdays = <String>[
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

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

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.yellow, size: 17),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupSelector extends StatelessWidget {
  const _GroupSelector({
    required this.groups,
    required this.selectedGroup,
    required this.onChanged,
  });

  final List<AttendanceTrainingGroup> groups;
  final AttendanceTrainingGroup? selectedGroup;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.13)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          isDense: false,
          itemHeight: 58,
          value: selectedGroup?.id,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.fuchsia,
          ),
          hint: const Text(
            'Selecciona un grupo',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          items: groups.map((AttendanceTrainingGroup group) {
            return DropdownMenuItem<String>(
              value: group.id,
              child: SizedBox(
                height: 54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${group.displaySchedule} · '
                      '${group.displayLocation}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF81747A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _AttendanceSummary extends StatelessWidget {
  const _AttendanceSummary({
    required this.total,
    required this.present,
    required this.late,
    required this.absent,
    required this.injured,
  });

  final int total;
  final int present;
  final int late;
  final int absent;
  final int injured;

  @override
  Widget build(BuildContext context) {
    final List<_SummaryData> items = <_SummaryData>[
      _SummaryData(
        label: 'Total',
        value: total,
        icon: Icons.groups_rounded,
        color: AppColors.fuchsia,
      ),
      _SummaryData(
        label: 'Presentes',
        value: present,
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF168A55),
      ),
      _SummaryData(
        label: 'Tarde',
        value: late,
        icon: Icons.schedule_rounded,
        color: const Color(0xFFF9A825),
      ),
      _SummaryData(
        label: 'Ausentes',
        value: absent,
        icon: Icons.cancel_rounded,
        color: const Color(0xFFC62828),
      ),
      _SummaryData(
        label: 'Lesionados',
        value: injured,
        icon: Icons.healing_rounded,
        color: const Color(0xFF6A1B9A),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 750
            ? 5
            : constraints.maxWidth >= 480
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (BuildContext context, int index) {
            return _SummaryCard(data: items[index]);
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: data.color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.value}',
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF81747A),
                    fontSize: 10.5,
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

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.total, required this.onMarkAllPresent});

  final int total;
  final VoidCallback onMarkAllPresent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$total jugadores',
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onMarkAllPresent,
          icon: const Icon(Icons.done_all_rounded),
          label: const Text(
            'TODOS PRESENTES',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _AttendancePlayerCard extends StatelessWidget {
  const _AttendancePlayerCard({required this.attendance, required this.onTap});

  final AttendanceModel attendance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _StatusStyle style = _StatusStyle.fromStatus(attendance.status);

    final String initials = _initials(attendance.playerName);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: style.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: style.color, width: 2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: style.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendance.playerName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Código: ${attendance.playerCode}',
                      style: const TextStyle(
                        color: Color(0xFF81747A),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                constraints: const BoxConstraints(minWidth: 105),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(style.icon, color: style.color, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        style.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: style.color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
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

  static String _initials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _EmptyAttendance extends StatelessWidget {
  const _EmptyAttendance();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.groups_outlined, color: AppColors.fuchsia, size: 58),
          SizedBox(height: 14),
          Text(
            'No hay jugadores en este grupo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Asigna jugadores al grupo para comenzar a registrar asistencia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF81747A), height: 1.4),
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

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  factory _StatusStyle.fromStatus(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const _StatusStyle(
          label: 'Presente',
          color: Color(0xFF168A55),
          icon: Icons.check_circle_rounded,
        );

      case AttendanceStatus.late:
        return const _StatusStyle(
          label: 'Tarde',
          color: Color(0xFFF9A825),
          icon: Icons.schedule_rounded,
        );

      case AttendanceStatus.absent:
        return const _StatusStyle(
          label: 'Ausente',
          color: Color(0xFFC62828),
          icon: Icons.cancel_rounded,
        );

      case AttendanceStatus.injured:
        return const _StatusStyle(
          label: 'Lesionado',
          color: Color(0xFF6A1B9A),
          icon: Icons.healing_rounded,
        );
    }
  }
}

class _SummaryData {
  const _SummaryData({
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
