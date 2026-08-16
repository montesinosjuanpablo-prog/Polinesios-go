import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/player_model.dart';

class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({
    required this.player,
    this.onAttendancePressed,
    this.onPaymentsPressed,
    this.onStatisticsPressed,
    super.key,
  });

  final PlayerModel player;

  final VoidCallback? onAttendancePressed;
  final VoidCallback? onPaymentsPressed;
  final VoidCallback? onStatisticsPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Ficha profesional',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 940),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PlayerHeader(player: player),
                    const SizedBox(height: 18),
                    _QuickSummary(player: player),
                    const SizedBox(height: 18),
                    _ResponsiveSections(player: player),
                    const SizedBox(height: 18),
                    _ProfileActions(
                      onStatisticsPressed: onStatisticsPressed,
                      onAttendancePressed: onAttendancePressed,
                      onPaymentsPressed: onPaymentsPressed,
                    ),
                    const SizedBox(height: 22),
                    const _InstitutionalPhrase(),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text(
                          'VOLVER',
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
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({required this.player});

  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia, Color(0xFF8B004D)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.fuchsia.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 560;

          final Widget photo = _PlayerPhoto(player: player);

          final Widget information = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                player.fullName,
                textAlign: compact ? TextAlign.center : TextAlign.left,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                player.displayCategory,
                textAlign: compact ? TextAlign.center : TextAlign.left,
                style: const TextStyle(
                  color: AppColors.yellow,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 13),
              Wrap(
                alignment: compact ? WrapAlignment.center : WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeaderBadge(
                    icon: Icons.badge_rounded,
                    text: player.playerCode,
                  ),
                  _HeaderBadge(
                    icon: Icons.cake_rounded,
                    text: '${player.age} años',
                  ),
                  _HeaderBadge(
                    icon: player.isActive
                        ? Icons.verified_rounded
                        : Icons.pause_circle_rounded,
                    text: player.isActive
                        ? 'ACTIVO'
                        : _statusLabel(player.status),
                    highlight: true,
                  ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [photo, const SizedBox(height: 18), information],
            );
          }

          return Row(
            children: [
              photo,
              const SizedBox(width: 20),
              Expanded(child: information),
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(String status) {
    final String normalized = status.trim().toLowerCase();

    switch (normalized) {
      case 'inactive':
        return 'INACTIVO';
      case 'suspended':
        return 'SUSPENDIDO';
      default:
        return status.trim().isEmpty
            ? 'SIN ESTADO'
            : status.trim().toUpperCase();
    }
  }
}

class _PlayerPhoto extends StatelessWidget {
  const _PlayerPhoto({required this.player});

  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    final String photoUrl = player.photoUrl?.trim() ?? '';

    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        color: AppColors.yellow,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl.isEmpty
          ? _InitialsAvatar(initials: player.initials)
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return _InitialsAvatar(initials: player.initials);
                  },
            ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials.trim().isEmpty ? '?' : initials,
        style: const TextStyle(
          color: AppColors.black,
          fontSize: 35,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  final IconData icon;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.yellow
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? AppColors.yellow
              : Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: highlight ? AppColors.black : AppColors.white,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: highlight ? AppColors.black : AppColors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSummary extends StatelessWidget {
  const _QuickSummary({required this.player});

  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    final List<_SummaryData> items = <_SummaryData>[
      _SummaryData(
        label: 'Categoría',
        value: player.displayCategory,
        icon: Icons.groups_rounded,
        color: AppColors.fuchsia,
      ),
      _SummaryData(
        label: 'Grupo',
        value: player.displayTrainingGroup,
        icon: Icons.sports_soccer_rounded,
        color: const Color(0xFF1565C0),
      ),
      _SummaryData(
        label: 'Posición',
        value: player.displayPosition,
        icon: Icons.flag_rounded,
        color: const Color(0xFF168A55),
      ),
      _SummaryData(
        label: 'Antigüedad',
        value: _registrationTime(player.registrationDate),
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFE59A00),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 820
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1
                ? 3.5
                : columns == 2
                ? 2.25
                : 1.55,
          ),
          itemBuilder: (BuildContext context, int index) {
            return _SummaryCard(data: items[index]);
          },
        );
      },
    );
  }

  static String _registrationTime(DateTime registrationDate) {
    final DateTime now = DateTime.now();

    int months =
        (now.year - registrationDate.year) * 12 +
        now.month -
        registrationDate.month;

    if (now.day < registrationDate.day) {
      months--;
    }

    if (months <= 0) {
      return 'Nuevo ingreso';
    }

    if (months < 12) {
      return months == 1 ? '1 mes' : '$months meses';
    }

    final int years = months ~/ 12;
    final int remainingMonths = months % 12;

    if (remainingMonths == 0) {
      return years == 1 ? '1 año' : '$years años';
    }

    return '$years a $remainingMonths m';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: data.color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(
                    color: Color(0xFF81747A),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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

class _ResponsiveSections extends StatelessWidget {
  const _ResponsiveSections({required this.player});

  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final List<Widget> sections = <Widget>[
          _InformationSection(
            title: 'Datos personales',
            icon: Icons.person_rounded,
            color: AppColors.fuchsia,
            items: <_InformationItem>[
              _InformationItem(
                label: 'Nombre completo',
                value: player.fullName,
                icon: Icons.person_outline_rounded,
              ),
              _InformationItem(
                label: 'Cédula de identidad',
                value: _nullableText(player.ci),
                icon: Icons.badge_outlined,
              ),
              _InformationItem(
                label: 'Fecha de nacimiento',
                value: _formatDate(player.birthDate),
                icon: Icons.cake_outlined,
              ),
              _InformationItem(
                label: 'Edad',
                value: '${player.age} años',
                icon: Icons.timeline_rounded,
              ),
              _InformationItem(
                label: 'Género',
                value: _nullableText(player.gender),
                icon: Icons.wc_rounded,
              ),
              _InformationItem(
                label: 'Dirección',
                value: _nullableText(player.address),
                icon: Icons.home_outlined,
              ),
              _InformationItem(
                label: 'Unidad educativa',
                value: _nullableText(player.schoolName),
                icon: Icons.school_outlined,
              ),
            ],
          ),
          _InformationSection(
            title: 'Perfil deportivo',
            icon: Icons.sports_soccer_rounded,
            color: const Color(0xFF1565C0),
            items: <_InformationItem>[
              _InformationItem(
                label: 'Posición principal',
                value: player.displayPosition,
                icon: Icons.flag_outlined,
              ),
              _InformationItem(
                label: 'Posición secundaria',
                value: _nullableText(player.secondaryPosition),
                icon: Icons.swap_horiz_rounded,
              ),
              _InformationItem(
                label: 'Pierna hábil',
                value: _nullableText(player.dominantFoot),
                icon: Icons.directions_run_rounded,
              ),
              _InformationItem(
                label: 'Estatura',
                value: _formatHeight(player.heightCm),
                icon: Icons.height_rounded,
              ),
              _InformationItem(
                label: 'Peso',
                value: _formatWeight(player.weightKg),
                icon: Icons.monitor_weight_outlined,
              ),
              _InformationItem(
                label: 'Categoría',
                value: player.displayCategory,
                icon: Icons.groups_outlined,
              ),
              _InformationItem(
                label: 'Grupo de entrenamiento',
                value: player.displayTrainingGroup,
                icon: Icons.group_work_outlined,
              ),
            ],
          ),
          _InformationSection(
            title: 'Indumentaria',
            icon: Icons.checkroom_rounded,
            color: const Color(0xFFE59A00),
            items: <_InformationItem>[
              _InformationItem(
                label: 'Talla de camiseta',
                value: _nullableText(player.shirtSize),
                icon: Icons.checkroom_outlined,
              ),
              _InformationItem(
                label: 'Talla de corto',
                value: _nullableText(player.shortsSize),
                icon: Icons.straighten_rounded,
              ),
              _InformationItem(
                label: 'Talla de medias',
                value: _nullableText(player.socksSize),
                icon: Icons.rule_rounded,
              ),
            ],
          ),
          _InformationSection(
            title: 'Información administrativa',
            icon: Icons.folder_shared_rounded,
            color: const Color(0xFF168A55),
            items: <_InformationItem>[
              _InformationItem(
                label: 'Código del jugador',
                value: player.playerCode,
                icon: Icons.qr_code_rounded,
              ),
              _InformationItem(
                label: 'Fecha de inscripción',
                value: _formatDate(player.registrationDate),
                icon: Icons.calendar_month_outlined,
              ),
              _InformationItem(
                label: 'Estado',
                value: player.isActive
                    ? 'Activo'
                    : _nullableText(player.status),
                icon: player.isActive
                    ? Icons.verified_outlined
                    : Icons.info_outline_rounded,
              ),
              _InformationItem(
                label: 'Última actualización',
                value: player.updatedAt == null
                    ? 'Sin información'
                    : _formatDateTime(player.updatedAt!),
                icon: Icons.update_rounded,
              ),
            ],
          ),
        ];

        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              for (int index = 0; index < sections.length; index++) ...[
                sections[index],
                if (index != sections.length - 1) const SizedBox(height: 14),
              ],
            ],
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sections.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (BuildContext context, int index) {
            return sections[index];
          },
        );
      },
    );
  }

  static String _nullableText(String? value) {
    final String normalized = value?.trim() ?? '';

    return normalized.isEmpty ? 'Sin información' : normalized;
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} '
        '$hour:$minute';
  }

  static String _formatHeight(double? value) {
    if (value == null || value <= 0) {
      return 'Sin información';
    }

    if (value >= 100) {
      return '${value.toStringAsFixed(0)} cm';
    }

    return '${value.toStringAsFixed(2)} m';
  }

  static String _formatWeight(double? value) {
    if (value == null || value <= 0) {
      return 'Sin información';
    }

    final bool wholeNumber = value == value.roundToDouble();

    return wholeNumber
        ? '${value.toStringAsFixed(0)} kg'
        : '${value.toStringAsFixed(1)} kg';
  }
}

class _InformationSection extends StatelessWidget {
  const _InformationSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<_InformationItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int index = 0; index < items.length; index++) ...[
            _InformationRow(item: items[index], color: color),
            if (index != items.length - 1) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.item, required this.color});

  final _InformationItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item.icon, color: color, size: 21),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  color: Color(0xFF81747A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.value,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 13.5,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({
    required this.onStatisticsPressed,
    required this.onAttendancePressed,
    required this.onPaymentsPressed,
  });

  final VoidCallback? onStatisticsPressed;
  final VoidCallback? onAttendancePressed;
  final VoidCallback? onPaymentsPressed;

  @override
  Widget build(BuildContext context) {
    final List<_ActionData> actions = <_ActionData>[
      _ActionData(
        label: 'ESTADÍSTICAS',
        icon: Icons.bar_chart_rounded,
        onPressed: onStatisticsPressed,
      ),
      _ActionData(
        label: 'ASISTENCIA',
        icon: Icons.fact_check_rounded,
        onPressed: onAttendancePressed,
      ),
      _ActionData(
        label: 'PAGOS',
        icon: Icons.payments_rounded,
        onPressed: onPaymentsPressed,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 620;

        if (compact) {
          return Column(
            children: [
              for (int index = 0; index < actions.length; index++) ...[
                _ProfileActionButton(data: actions[index]),
                if (index != actions.length - 1) const SizedBox(height: 11),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int index = 0; index < actions.length; index++) ...[
              Expanded(child: _ProfileActionButton(data: actions[index])),
              if (index != actions.length - 1) const SizedBox(width: 11),
            ],
          ],
        );
      },
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({required this.data});

  final _ActionData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed:
            data.onPressed ??
            () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.fuchsia,
                    content: Text(
                      'El acceso a '
                      '${data.label.toLowerCase()} '
                      'se conectará en el siguiente paso.',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
            },
        icon: Icon(data.icon),
        label: Text(
          data.label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.fuchsia,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
}

class _InstitutionalPhrase extends StatelessWidget {
  const _InstitutionalPhrase();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '“Nunca dejes de Soñar, '
      'Nunca dejes de Intentar, '
      'Nunca te Rindas.”',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.darkFuchsia,
        fontSize: 14,
        height: 1.5,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w800,
      ),
    );
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
  final String value;
  final IconData icon;
  final Color color;
}

class _InformationItem {
  const _InformationItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _ActionData {
  const _ActionData({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}
