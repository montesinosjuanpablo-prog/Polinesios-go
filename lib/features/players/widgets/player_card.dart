import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/player_model.dart';

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    required this.player,
    required this.onTap,
    this.onEditPressed,
    super.key,
  });

  final PlayerModel player;
  final VoidCallback onTap;
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    final _PlayerStatusStyle statusStyle = _PlayerStatusStyle.fromStatus(
      player.status,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 420;

        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: AppColors.fuchsia.withValues(alpha: 0.12)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: 13,
              ),
              child: compact
                  ? _CompactPlayerLayout(
                      player: player,
                      statusStyle: statusStyle,
                      onTap: onTap,
                      onEditPressed: onEditPressed,
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _PlayerAvatar(player: player),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _PlayerInformation(
                            player: player,
                            statusStyle: statusStyle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PlayerActions(
                          onViewPressed: onTap,
                          onEditPressed: onEditPressed,
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _CompactPlayerLayout extends StatelessWidget {
  const _CompactPlayerLayout({
    required this.player,
    required this.statusStyle,
    required this.onTap,
    required this.onEditPressed,
  });

  final PlayerModel player;
  final _PlayerStatusStyle statusStyle;
  final VoidCallback onTap;
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _PlayerAvatar(player: player, compact: true),
        const SizedBox(width: 11),
        Expanded(
          child: _PlayerInformation(
            player: player,
            statusStyle: statusStyle,
            compact: true,
          ),
        ),
        const SizedBox(width: 6),
        _PlayerActions(
          onViewPressed: onTap,
          onEditPressed: onEditPressed,
          compact: true,
        ),
      ],
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.player, this.compact = false});

  final PlayerModel player;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = player.photoUrl?.trim();
    final bool hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    final double size = compact ? 58 : 68;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.fuchsia, AppColors.darkFuchsia],
        ),
        border: Border.all(color: AppColors.yellow, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.fuchsia.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return _PlayerInitials(
                        initials: player.initials,
                        compact: compact,
                      );
                    },
              )
            : _PlayerInitials(initials: player.initials, compact: compact),
      ),
    );
  }
}

class _PlayerInitials extends StatelessWidget {
  const _PlayerInitials({required this.initials, this.compact = false});

  final String initials;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: TextStyle(
            color: AppColors.white,
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _PlayerInformation extends StatelessWidget {
  const _PlayerInformation({
    required this.player,
    required this.statusStyle,
    this.compact = false,
  });

  final PlayerModel player;
  final _PlayerStatusStyle statusStyle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          player.fullName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.black,
            fontSize: compact ? 15 : 17,
            fontWeight: FontWeight.w900,
            height: 1.10,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Código: ${player.playerCode}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF81747A),
            fontSize: compact ? 10.5 : 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: compact ? 4 : 6,
          runSpacing: 5,
          children: [
            _InformationChip(
              icon: Icons.cake_outlined,
              label: '${player.age} años',
              compact: compact,
            ),
            _InformationChip(
              icon: Icons.groups_rounded,
              label: player.displayCategory,
              compact: compact,
            ),
            _InformationChip(
              icon: Icons.schedule_rounded,
              label: player.displayTrainingGroup,
              compact: compact,
            ),
          ],
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: compact ? 5 : 7,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatusBadge(style: statusStyle, compact: compact),
            if (player.primaryPosition != null)
              _PositionBadge(
                position: player.displayPosition,
                compact: compact,
              ),
          ],
        ),
      ],
    );
  }
}

class _InformationChip extends StatelessWidget {
  const _InformationChip({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: compact ? 150 : 170),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE2E7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 14, color: AppColors.fuchsia),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF5F5359),
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.style, this.compact = false});

  final _PlayerStatusStyle style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: style.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.position, this.compact = false});

  final String position;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: compact ? 120 : 150),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.23),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sports_soccer_rounded,
            color: AppColors.black,
            size: 14,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              position,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.black,
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerActions extends StatelessWidget {
  const _PlayerActions({
    required this.onViewPressed,
    required this.onEditPressed,
    this.compact = false,
  });

  final VoidCallback onViewPressed;
  final VoidCallback? onEditPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 36 : 42;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: IconButton(
            onPressed: onViewPressed,
            tooltip: 'Ver jugador',
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.fuchsia,
              backgroundColor: AppColors.fuchsia.withValues(alpha: 0.10),
            ),
            icon: Icon(Icons.chevron_right_rounded, size: compact ? 21 : 23),
          ),
        ),
        if (onEditPressed != null) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: size,
            height: size,
            child: IconButton(
              onPressed: onEditPressed,
              tooltip: 'Editar jugador',
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                foregroundColor: AppColors.black,
                backgroundColor: AppColors.yellow.withValues(alpha: 0.38),
              ),
              icon: Icon(Icons.edit_outlined, size: compact ? 17 : 19),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlayerStatusStyle {
  const _PlayerStatusStyle({required this.label, required this.color});

  final String label;
  final Color color;

  factory _PlayerStatusStyle.fromStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return const _PlayerStatusStyle(
          label: 'Activo',
          color: Color(0xFF168A55),
        );

      case 'inactive':
        return const _PlayerStatusStyle(
          label: 'Inactivo',
          color: Color(0xFF777777),
        );

      case 'withdrawn':
        return const _PlayerStatusStyle(
          label: 'Retirado',
          color: Color(0xFFB65D00),
        );

      case 'suspended':
        return const _PlayerStatusStyle(
          label: 'Suspendido',
          color: Color(0xFFC62828),
        );

      default:
        return const _PlayerStatusStyle(
          label: 'Sin estado',
          color: Color(0xFF777777),
        );
    }
  }
}
