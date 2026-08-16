import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../payments/presentation/payment_account_screen.dart';
import '../models/player_detail_model.dart';
import '../models/player_model.dart';
import '../repositories/player_repository.dart';
import 'add_player_screen.dart';
import 'player_attendance_screen.dart';
import 'player_guardians_screen.dart';
import 'player_medical_screen.dart';
import 'widgets/player_bottom_actions.dart';
import 'widgets/player_detail_header.dart';
import 'widgets/player_error_message.dart';
import 'widgets/player_information_section.dart';
import 'widgets/player_modules_section.dart';
import 'widgets/player_quick_statistics.dart';

class PlayerDetailScreen extends StatefulWidget {
  const PlayerDetailScreen({required this.player, super.key});

  final PlayerModel player;

  @override
  State<PlayerDetailScreen> createState() {
    return _PlayerDetailScreenState();
  }
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  final PlayerRepository _repository = const PlayerRepository();

  late PlayerModel _player;
  PlayerDetailModel? _playerDetail;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _player = widget.player;
    _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final PlayerDetailModel detail = await _repository.getPlayerDetailById(
        widget.player.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _playerDetail = detail;
        _player = detail.player;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error al cargar la ficha del jugador: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'No fue posible actualizar la ficha del jugador.';
      });
    }
  }

  Future<void> _refreshPlayer() async {
    await _loadPlayer();
  }

  void _openModule(String moduleName) {
    switch (moduleName) {
      case 'Pagos':
        _openPayments();
        return;

      case 'Asistencia':
        _openAttendance();
        return;

      case 'Tutor y familia':
        _openGuardians();
        return;

      case 'Información médica':
        _openMedicalInformation();
        return;

      case 'Rendimiento':
        _showMessage(
          'Este módulo formará parte de la versión 2 de Polinesios GO.',
        );
        return;

      default:
        _showMessage('$moduleName estará disponible próximamente.');
    }
  }

  void _openPayments() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          return PaymentAccountScreen(player: _player);
        },
      ),
    );
  }

  void _openAttendance() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          return PlayerAttendanceScreen(player: _player);
        },
      ),
    );
  }

  void _openGuardians() {
    final PlayerDetailModel? detail = _playerDetail;

    if (detail == null) {
      _showMessage('Todavía estamos cargando los datos familiares.');
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          return PlayerGuardiansScreen(
            player: detail.player,
            guardians: detail.guardians,
          );
        },
      ),
    );
  }

  void _openMedicalInformation() {
    final PlayerDetailModel? detail = _playerDetail;

    if (detail == null) {
      _showMessage('Todavía estamos cargando la información médica.');
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          return PlayerMedicalScreen(
            player: detail.player,
            medical: detail.medical,
          );
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.fuchsia,
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  Future<void> _openPlayerEditor() async {
    final bool? playerWasUpdated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddPlayerScreen(playerId: _player.id),
      ),
    );

    if (!mounted || playerWasUpdated != true) {
      return;
    }

    await _refreshPlayer();

    if (!mounted) {
      return;
    }

    _showMessage('Los datos del jugador fueron actualizados correctamente.');
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
          'Ficha profesional',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _refreshPlayer,
            tooltip: 'Actualizar ficha',
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _isLoading ? null : _openPlayerEditor,
            tooltip: 'Editar jugador',
            icon: const Icon(Icons.edit_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.fuchsia,
          onRefresh: _refreshPlayer,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isLoading)
                            const LinearProgressIndicator(
                              minHeight: 3,
                              color: AppColors.yellow,
                              backgroundColor: Color(0xFFE6D3DE),
                            ),
                          if (_isLoading) const SizedBox(height: 12),
                          if (_errorMessage != null)
                            PlayerErrorMessage(
                              message: _errorMessage!,
                              onRetry: _loadPlayer,
                            ),
                          if (_errorMessage != null) const SizedBox(height: 16),
                          PlayerDetailHeader(player: _player),
                          const SizedBox(height: 18),
                          PlayerQuickStatistics(player: _player),
                          const SizedBox(height: 18),
                          PlayerResponsiveSections(
                            first: _buildPersonalInformation(),
                            second: _buildSportInformation(),
                          ),
                          const SizedBox(height: 18),
                          PlayerResponsiveSections(
                            first: _buildClothingInformation(),
                            second: _buildRegistrationInformation(),
                          ),
                          const SizedBox(height: 18),
                          PlayerModulesSection(onModulePressed: _openModule),
                          const SizedBox(height: 22),
                          PlayerBottomActions(
                            onEditPressed: _openPlayerEditor,
                            onBackPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return PlayerInformationSection(
      title: 'Información personal',
      subtitle: 'Datos generales del jugador',
      icon: Icons.person_rounded,
      children: [
        PlayerDetailRow(
          icon: Icons.badge_outlined,
          label: 'Código del jugador',
          value: _player.playerCode,
        ),
        PlayerDetailRow(
          icon: Icons.credit_card_rounded,
          label: 'Documento de identidad',
          value: _displayText(_player.ci),
        ),
        PlayerDetailRow(
          icon: Icons.cake_outlined,
          label: 'Fecha de nacimiento',
          value: _formatDate(_player.birthDate),
        ),
        PlayerDetailRow(
          icon: Icons.calendar_month_rounded,
          label: 'Edad',
          value: '${_player.age} años',
        ),
        PlayerDetailRow(
          icon: Icons.people_alt_outlined,
          label: 'Género',
          value: _genderLabel(_player.gender),
        ),
        PlayerDetailRow(
          icon: Icons.home_outlined,
          label: 'Dirección',
          value: _displayText(_player.address),
        ),
        PlayerDetailRow(
          icon: Icons.school_outlined,
          label: 'Unidad educativa',
          value: _displayText(_player.schoolName),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildSportInformation() {
    return PlayerInformationSection(
      title: 'Información deportiva',
      subtitle: 'Perfil futbolístico',
      icon: Icons.sports_soccer_rounded,
      children: [
        PlayerDetailRow(
          icon: Icons.groups_rounded,
          label: 'Categoría',
          value: _player.displayCategory,
        ),
        PlayerDetailRow(
          icon: Icons.calendar_view_week_rounded,
          label: 'Grupo de entrenamiento',
          value: _player.displayTrainingGroup,
        ),
        PlayerDetailRow(
          icon: Icons.flag_rounded,
          label: 'Posición principal',
          value: _player.displayPosition,
        ),
        PlayerDetailRow(
          icon: Icons.swap_horiz_rounded,
          label: 'Posición secundaria',
          value: _displayText(_player.secondaryPosition),
        ),
        PlayerDetailRow(
          icon: Icons.directions_run_rounded,
          label: 'Pie dominante',
          value: _dominantFootLabel(_player.dominantFoot),
        ),
        PlayerDetailRow(
          icon: Icons.height_rounded,
          label: 'Estatura',
          value: _measurement(_player.heightCm, 'cm'),
        ),
        PlayerDetailRow(
          icon: Icons.monitor_weight_outlined,
          label: 'Peso',
          value: _measurement(_player.weightKg, 'kg'),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildClothingInformation() {
    return PlayerInformationSection(
      title: 'Indumentaria',
      subtitle: 'Tallas registradas',
      icon: Icons.checkroom_rounded,
      children: [
        PlayerDetailRow(
          icon: Icons.sports_soccer_outlined,
          label: 'Talla de camiseta',
          value: _displayText(_player.shirtSize),
        ),
        PlayerDetailRow(
          icon: Icons.straighten_rounded,
          label: 'Talla de corto',
          value: _displayText(_player.shortsSize),
        ),
        PlayerDetailRow(
          icon: Icons.dry_cleaning_outlined,
          label: 'Talla de medias',
          value: _displayText(_player.socksSize),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildRegistrationInformation() {
    final bool isActive = _player.isActive;

    return PlayerInformationSection(
      title: 'Inscripción y estado',
      subtitle: 'Información administrativa',
      icon: Icons.verified_user_rounded,
      children: [
        PlayerDetailRow(
          icon: Icons.event_available_rounded,
          label: 'Fecha de inscripción',
          value: _formatDate(_player.registrationDate),
        ),
        PlayerDetailRow(
          icon: Icons.history_rounded,
          label: 'Fecha de creación',
          value: _formatNullableDate(_player.createdAt),
        ),
        PlayerDetailRow(
          icon: Icons.update_rounded,
          label: 'Última actualización',
          value: _formatNullableDate(_player.updatedAt),
        ),
        PlayerDetailRow(
          icon: isActive
              ? Icons.check_circle_rounded
              : Icons.pause_circle_rounded,
          label: 'Estado',
          value: isActive ? 'Jugador activo' : _statusLabel(_player.status),
          valueColor: isActive
              ? const Color(0xFF168A55)
              : const Color(0xFFC62828),
          showDivider: false,
        ),
      ],
    );
  }

  static String _displayText(String? value) {
    final String text = value?.trim() ?? '';

    return text.isEmpty ? 'No registrado' : text;
  }

  static String _measurement(double? value, String unit) {
    if (value == null) {
      return 'No registrado';
    }

    final String number = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);

    return '$number $unit';
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static String _formatNullableDate(DateTime? date) {
    if (date == null) {
      return 'No registrado';
    }

    return _formatDate(date);
  }

  static String _genderLabel(String? gender) {
    switch (gender?.trim().toLowerCase()) {
      case 'male':
      case 'masculino':
        return 'Masculino';

      case 'female':
      case 'femenino':
        return 'Femenino';

      case 'other':
      case 'otro':
        return 'Otro';

      default:
        return 'No registrado';
    }
  }

  static String _dominantFootLabel(String? foot) {
    switch (foot?.trim().toLowerCase()) {
      case 'right':
      case 'derecho':
      case 'derecha':
        return 'Derecho';

      case 'left':
      case 'izquierdo':
      case 'izquierda':
        return 'Izquierdo';

      case 'both':
      case 'ambidextrous':
      case 'ambos':
        return 'Ambidiestro';

      default:
        return 'No registrado';
    }
  }

  static String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'inactive':
        return 'Jugador inactivo';

      case 'withdrawn':
        return 'Jugador retirado';

      case 'suspended':
        return 'Jugador suspendido';

      default:
        return 'Estado no definido';
    }
  }
}
