import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../models/player_model.dart';

class PlayerQuickStatistics extends StatelessWidget {
  const PlayerQuickStatistics({required this.player, super.key});

  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    final List<_StatisticData> statistics = <_StatisticData>[
      _StatisticData(
        value: '${player.age}',
        label: 'Años',
        icon: Icons.cake_rounded,
        color: AppColors.fuchsia,
      ),
      _StatisticData(
        value: _formatNumber(player.heightCm),
        label: 'Altura cm',
        icon: Icons.height_rounded,
        color: const Color(0xFF1565C0),
      ),
      _StatisticData(
        value: _formatNumber(player.weightKg),
        label: 'Peso kg',
        icon: Icons.monitor_weight_outlined,
        color: const Color(0xFF7B1FA2),
      ),
      _StatisticData(
        value: _shortFoot(player.dominantFoot),
        label: 'Pie hábil',
        icon: Icons.directions_run_rounded,
        color: const Color(0xFF168A55),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 700 ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statistics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth >= 700 ? 1.65 : 1.45,
          ),
          itemBuilder: (BuildContext context, int index) {
            return _StatisticCard(data: statistics[index]);
          },
        );
      },
    );
  }

  static String _formatNumber(double? value) {
    if (value == null || value <= 0) {
      return '—';
    }

    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  static String _shortFoot(String? foot) {
    switch (foot?.trim().toLowerCase()) {
      case 'right':
      case 'derecho':
      case 'derecha':
        return 'DER';

      case 'left':
      case 'izquierdo':
      case 'izquierda':
        return 'IZQ';

      case 'both':
      case 'ambidextrous':
      case 'ambos':
        return 'AMB';

      default:
        return '—';
    }
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({required this.data});

  final _StatisticData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: data.color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 13,
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
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF786C72),
                    fontSize: 11.5,
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

class _StatisticData {
  const _StatisticData({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
}
