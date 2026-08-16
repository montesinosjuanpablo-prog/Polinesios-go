import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/player_detail_model.dart';
import '../models/player_model.dart';

class PlayerMedicalScreen extends StatelessWidget {
  const PlayerMedicalScreen({
    required this.player,
    required this.medical,
    super.key,
  });

  final PlayerModel player;
  final PlayerMedicalData medical;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Información médica',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            34,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 820,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  _PlayerBanner(player: player),
                  const SizedBox(height: 18),
                  _MedicalSummary(medical: medical),
                  const SizedBox(height: 18),
                  _MedicalSection(
                    title: 'Datos generales de salud',
                    icon:
                        Icons.medical_information_rounded,
                    children: [
                      _MedicalDetailRow(
                        icon: Icons.bloodtype_rounded,
                        label: 'Tipo de sangre',
                        value: _display(
                          medical.bloodType,
                        ),
                      ),
                      _MedicalDetailRow(
                        icon: Icons.air_rounded,
                        label: 'Asma',
                        value:
                            medical.hasAsthma ? 'Sí' : 'No',
                      ),
                      _MedicalDetailRow(
                        icon:
                            Icons.health_and_safety_rounded,
                        label: 'Seguro médico',
                        value: _display(
                          medical.medicalInsurance,
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _MedicalSection(
                    title: 'Antecedentes y cuidados',
                    icon: Icons.healing_rounded,
                    children: [
                      _MedicalDetailRow(
                        icon:
                            Icons.warning_amber_rounded,
                        label: 'Alergias',
                        value: _display(
                          medical.allergies,
                        ),
                      ),
                      _MedicalDetailRow(
                        icon:
                            Icons.medication_rounded,
                        label: 'Medicamentos',
                        value: _display(
                          medical.medications,
                        ),
                      ),
                      _MedicalDetailRow(
                        icon:
                            Icons.personal_injury_rounded,
                        label: 'Lesiones previas',
                        value: _display(
                          medical.previousInjuries,
                        ),
                      ),
                      _MedicalDetailRow(
                        icon:
                            Icons.local_hospital_rounded,
                        label: 'Cirugías',
                        value: _display(
                          medical.surgeries,
                        ),
                      ),
                      _MedicalDetailRow(
                        icon:
                            Icons.monitor_heart_rounded,
                        label:
                            'Condiciones médicas',
                        value: _display(
                          medical.medicalConditions,
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _EmergencyNotesCard(
                    notes: medical.emergencyNotes,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                      ),
                      label: const Text(
                        'VOLVER A LA FICHA',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            AppColors.fuchsia,
                        side: const BorderSide(
                          color: AppColors.fuchsia,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(17),
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

  static String _display(String? value) {
    final String text = value?.trim() ?? '';

    return text.isEmpty
        ? 'No registrado'
        : text;
  }
}

class _PlayerBanner extends StatelessWidget {
  const _PlayerBanner({
    required this.player,
  });

  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkFuchsia,
            AppColors.fuchsia,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.fuchsia
                .withValues(alpha: 0.22),
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
              border: Border.all(
                color: AppColors.white,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                player.initials.isEmpty
                    ? '?'
                    : player.initials,
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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

class _MedicalSummary extends StatelessWidget {
  const _MedicalSummary({
    required this.medical,
  });

  final PlayerMedicalData medical;

  @override
  Widget build(BuildContext context) {
    final Color color = medical.hasRelevantInformation
        ? const Color(0xFF168A55)
        : const Color(0xFF777777);

    final String title = medical.hasRelevantInformation
        ? 'Información médica registrada'
        : 'Sin información médica relevante';

    final String subtitle =
        medical.hasRelevantInformation
            ? 'La ficha contiene antecedentes de salud.'
            : 'No se registraron antecedentes médicos especiales.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              medical.hasRelevantInformation
                  ? Icons.health_and_safety_rounded
                  : Icons.check_circle_outline_rounded,
              color: color,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6F646A),
                    fontSize: 12.5,
                    height: 1.35,
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

class _MedicalSection extends StatelessWidget {
  const _MedicalSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.fuchsia
              .withValues(alpha: 0.11),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.045),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.fuchsia
                      .withValues(alpha: 0.11),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: AppColors.fuchsia,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _MedicalDetailRow extends StatelessWidget {
  const _MedicalDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: AppColors.fuchsia,
                size: 19,
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 135,
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
        ),
        if (showDivider)
          const Divider(height: 1),
      ],
    );
  }
}

class _EmergencyNotesCard extends StatelessWidget {
  const _EmergencyNotesCard({
    required this.notes,
  });

  final String? notes;

  @override
  Widget build(BuildContext context) {
    final String text = notes?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFCC80),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.emergency_rounded,
            color: Color(0xFFE65100),
            size: 28,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notas de emergencia',
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  text.isEmpty
                      ? 'No se registraron observaciones de emergencia.'
                      : text,
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
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