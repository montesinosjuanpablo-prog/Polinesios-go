import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../models/player_model.dart';

class PlayerDetailHeader extends StatelessWidget {
  const PlayerDetailHeader({required this.player, super.key});

  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    final String photoUrl = player.photoUrl?.trim() ?? '';

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

          final Widget avatar = Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 4),
            ),
            clipBehavior: Clip.antiAlias,
            child: photoUrl.isEmpty
                ? _InitialsAvatar(initials: player.initials)
                : Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return _InitialsAvatar(initials: player.initials);
                        },
                  ),
          );

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
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
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
                  _HeaderChip(
                    icon: Icons.badge_rounded,
                    label: player.playerCode,
                  ),
                  _HeaderChip(
                    icon: Icons.cake_rounded,
                    label: '${player.age} años',
                  ),
                  _HeaderChip(
                    icon: Icons.sports_soccer_rounded,
                    label: player.displayPosition,
                  ),
                  _StatusChip(isActive: player.isActive, status: player.status),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [avatar, const SizedBox(height: 18), information],
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: 20),
              Expanded(child: information),
            ],
          );
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
    return ColoredBox(
      color: AppColors.yellow,
      child: Center(
        child: Text(
          initials.trim().isEmpty ? '?' : initials,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 35,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive, required this.status});

  final bool isActive;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.verified_rounded : Icons.pause_circle_rounded,
            size: 17,
            color: AppColors.black,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'ACTIVO' : status.trim().toUpperCase(),
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
