import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/player_detail_model.dart';
import '../models/player_model.dart';

class PlayerGuardiansScreen extends StatelessWidget {
  const PlayerGuardiansScreen({
    required this.player,
    required this.guardians,
    super.key,
  });

  final PlayerModel player;
  final List<PlayerGuardianData> guardians;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Tutor y familia',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PlayerBanner(player: player),
                  const SizedBox(height: 18),
                  if (guardians.isEmpty)
                    const _EmptyGuardians()
                  else
                    ...guardians.map((PlayerGuardianData guardian) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _GuardianCard(guardian: guardian),
                      );
                    }),
                  const SizedBox(height: 6),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuardianCard extends StatelessWidget {
  const _GuardianCard({required this.guardian});

  final PlayerGuardianData guardian;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.11)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.fuchsia.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.family_restroom_rounded,
                  color: AppColors.fuchsia,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guardian.fullName,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      guardian.relationshipLabel,
                      style: const TextStyle(
                        color: Color(0xFF81747A),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (guardian.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'PRINCIPAL',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          _GuardianDetailRow(
            icon: Icons.credit_card_rounded,
            label: 'Documento',
            value: _display(guardian.ci),
          ),
          _GuardianDetailRow(
            icon: Icons.phone_rounded,
            label: 'Teléfono',
            value: _display(guardian.phone),
          ),
          _GuardianDetailRow(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            value: _display(guardian.whatsapp),
          ),
          _GuardianDetailRow(
            icon: Icons.email_outlined,
            label: 'Correo',
            value: _display(guardian.email),
          ),
          _GuardianDetailRow(
            icon: Icons.home_outlined,
            label: 'Dirección',
            value: _display(guardian.address),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PermissionBadge(
                enabled: guardian.canPickUp,
                label: 'Puede recoger',
                icon: Icons.directions_car_rounded,
              ),
              _PermissionBadge(
                enabled: guardian.receivesNotifications,
                label: 'Recibe avisos',
                icon: Icons.notifications_active_rounded,
              ),
              _PermissionBadge(
                enabled: guardian.hasFinancialResponsibility,
                label: 'Responsable de pagos',
                icon: Icons.payments_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _display(String? value) {
    final String text = value?.trim() ?? '';

    return text.isEmpty ? 'No registrado' : text;
  }
}

class _GuardianDetailRow extends StatelessWidget {
  const _GuardianDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.fuchsia, size: 19),
          const SizedBox(width: 10),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF81747A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionBadge extends StatelessWidget {
  const _PermissionBadge({
    required this.enabled,
    required this.label,
    required this.icon,
  });

  final bool enabled;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Color color = enabled
        ? const Color(0xFF168A55)
        : const Color(0xFF777777);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 5),
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGuardians extends StatelessWidget {
  const _EmptyGuardians();

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
          Icon(
            Icons.family_restroom_rounded,
            color: AppColors.fuchsia,
            size: 56,
          ),
          SizedBox(height: 14),
          Text(
            'No hay tutores relacionados',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Todavía no se encontraron datos familiares para este jugador.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF81747A), height: 1.4),
          ),
        ],
      ),
    );
  }
}
