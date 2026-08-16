import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../models/evaluation_model.dart';
import '../repositories/evaluation_repository.dart';

class EvaluationFormScreen extends StatefulWidget {
  const EvaluationFormScreen({this.evaluation, super.key});

  final EvaluationModel? evaluation;

  bool get isEditing => evaluation != null;

  @override
  State<EvaluationFormScreen> createState() {
    return _EvaluationFormScreenState();
  }
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final EvaluationRepository _repository = const EvaluationRepository();

  final TextEditingController _strengthsController = TextEditingController();

  final TextEditingController _areasToImproveController =
      TextEditingController();

  final TextEditingController _observationsController = TextEditingController();

  SupabaseClient get _client => Supabase.instance.client;

  List<_PlayerOption> _players = <_PlayerOption>[];

  String? _selectedPlayerId;

  DateTime _evaluationDate = DateTime.now();

  int _technicalScore = 3;
  int _tacticalScore = 3;
  int _physicalScore = 3;
  int _attitudeScore = 3;

  String _status = 'completed';

  String _schoolId = '';
  String _evaluatorId = '';

  bool _isLoadingPlayers = true;
  bool _isSaving = false;

  String? _playerError;

  @override
  void initState() {
    super.initState();

    final EvaluationModel? evaluation = widget.evaluation;

    if (evaluation != null) {
      _selectedPlayerId = evaluation.playerId;

      _evaluationDate = evaluation.evaluationDate;

      _technicalScore = evaluation.technicalScore;

      _tacticalScore = evaluation.tacticalScore;

      _physicalScore = evaluation.physicalScore;

      _attitudeScore = evaluation.attitudeScore;

      _strengthsController.text = evaluation.strengths;

      _areasToImproveController.text = evaluation.areasToImprove;

      _observationsController.text = evaluation.observations;

      _status = evaluation.status;

      _schoolId = evaluation.schoolId;
      _evaluatorId = evaluation.evaluatorId;
    }

    _loadPlayers();
  }

  @override
  void dispose() {
    _strengthsController.dispose();
    _areasToImproveController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoadingPlayers = true;
      _playerError = null;
    });

    try {
      final Map<String, dynamic> profile =
          await AuthService.getCurrentProfile();

      final String? schoolId = profile['school_id']?.toString();

      final String? evaluatorId = _client.auth.currentUser?.id;

      if (schoolId == null || schoolId.trim().isEmpty) {
        throw const AuthException(
          'El usuario actual no tiene una escuela asignada.',
        );
      }

      if (evaluatorId == null || evaluatorId.trim().isEmpty) {
        throw Exception('No fue posible identificar al evaluador.');
      }

      final List<dynamic> response = await _client
          .from('players')
          .select('''
                id,
                first_name,
                last_name
                ''')
          .eq('school_id', schoolId)
          .order('last_name')
          .order('first_name');

      final List<_PlayerOption> players = response
          .map((dynamic item) {
            final Map<String, dynamic> map = Map<String, dynamic>.from(
              item as Map,
            );

            return _PlayerOption(
              id: map['id']?.toString() ?? '',
              firstName: map['first_name']?.toString() ?? '',
              lastName: map['last_name']?.toString() ?? '',
            );
          })
          .where((_PlayerOption player) {
            return player.id.trim().isNotEmpty;
          })
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _schoolId = schoolId;
        _evaluatorId = evaluatorId;
        _players = players;
        _isLoadingPlayers = false;
      });
    } catch (error) {
      debugPrint('Error al cargar jugadores para evaluación: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingPlayers = false;
        _playerError = 'No fue posible cargar los jugadores.';
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _evaluationDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
      helpText: 'Fecha de evaluación',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _evaluationDate = selected;
    });
  }

  Future<void> _saveEvaluation() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final String? playerId = _selectedPlayerId;

    if (playerId == null || playerId.trim().isEmpty) {
      _showMessage('Selecciona un jugador.', isError: true);
      return;
    }

    _PlayerOption? selectedPlayer;

    for (final _PlayerOption player in _players) {
      if (player.id == playerId) {
        selectedPlayer = player;
        break;
      }
    }

    if (selectedPlayer == null) {
      _showMessage('No fue posible identificar al jugador.', isError: true);
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            widget.isEditing ? 'Guardar evaluación' : 'Registrar evaluación',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedPlayer!.fullName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text('Fecha: ${_formatDate(_evaluationDate)}'),
              const SizedBox(height: 5),
              Text('Técnica: $_technicalScore / 5'),
              Text('Táctica: $_tacticalScore / 5'),
              Text('Físico: $_physicalScore / 5'),
              Text('Actitud: $_attitudeScore / 5'),
              const SizedBox(height: 8),
              Text(
                'Promedio: ${_averageScore.toStringAsFixed(1)} / 5',
                style: const TextStyle(
                  color: AppColors.fuchsia,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text('Estado: ${_statusLabel(_status)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('VOLVER'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.fuchsia,
                foregroundColor: AppColors.white,
              ),
              child: Text(
                widget.isEditing
                    ? 'GUARDAR'
                    : _status == 'draft'
                    ? 'GUARDAR BORRADOR'
                    : 'REGISTRAR',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final EvaluationModel evaluation = EvaluationModel(
        id: widget.evaluation?.id ?? '',
        schoolId: _schoolId,
        playerId: playerId,
        evaluatorId: _evaluatorId,
        evaluationDate: _evaluationDate,
        technicalScore: _technicalScore,
        tacticalScore: _tacticalScore,
        physicalScore: _physicalScore,
        attitudeScore: _attitudeScore,
        strengths: _strengthsController.text.trim(),
        areasToImprove: _areasToImproveController.text.trim(),
        observations: _observationsController.text.trim(),
        status: _status,
        playerFirstName: selectedPlayer.firstName,
        playerLastName: selectedPlayer.lastName,
        evaluatorFirstName: widget.evaluation?.evaluatorFirstName ?? '',
        evaluatorLastName: widget.evaluation?.evaluatorLastName ?? '',
      );

      final EvaluationModel saved;

      if (widget.isEditing) {
        saved = await _repository.updateEvaluation(evaluation);
      } else {
        saved = await _repository.createEvaluation(evaluation);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<EvaluationModel>(saved);
    } catch (error) {
      debugPrint('Error al guardar evaluación: $error');

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text(
              'Error al guardar',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: SelectableText(error.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('CERRAR'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  double get _averageScore {
    return (_technicalScore +
            _tacticalScore +
            _physicalScore +
            _attitudeScore) /
        4;
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFC62828)
              : const Color(0xFF168A55),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        title: Text(
          widget.isEditing ? 'Editar evaluación' : 'Nueva evaluación',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
            children: [
              _FormCard(
                title: 'Jugador y fecha',
                icon: Icons.person_search_rounded,
                child: Column(
                  children: [
                    _buildPlayerSelector(),
                    const SizedBox(height: 16),
                    _PickerField(
                      label: 'Fecha de evaluación',
                      value: _formatDate(_evaluationDate),
                      icon: Icons.calendar_month_rounded,
                      onPressed: _selectDate,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _FormCard(
                title: 'Valoración',
                icon: Icons.insights_rounded,
                child: Column(
                  children: [
                    _ScoreSelector(
                      title: 'Técnica',
                      subtitle:
                          'Control, pase, conducción, remate y dominio del balón.',
                      icon: Icons.sports_soccer_rounded,
                      value: _technicalScore,
                      onChanged: (int value) {
                        setState(() {
                          _technicalScore = value;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    _ScoreSelector(
                      title: 'Táctica',
                      subtitle:
                          'Comprensión del juego, posicionamiento y toma de decisiones.',
                      icon: Icons.schema_rounded,
                      value: _tacticalScore,
                      onChanged: (int value) {
                        setState(() {
                          _tacticalScore = value;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    _ScoreSelector(
                      title: 'Físico',
                      subtitle:
                          'Coordinación, velocidad, resistencia y condición física.',
                      icon: Icons.fitness_center_rounded,
                      value: _physicalScore,
                      onChanged: (int value) {
                        setState(() {
                          _physicalScore = value;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    _ScoreSelector(
                      title: 'Actitud',
                      subtitle:
                          'Compromiso, respeto, esfuerzo, convivencia y disposición.',
                      icon: Icons.favorite_rounded,
                      value: _attitudeScore,
                      onChanged: (int value) {
                        setState(() {
                          _attitudeScore = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _AverageCard(average: _averageScore),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _FormCard(
                title: 'Seguimiento formativo',
                icon: Icons.edit_note_rounded,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _strengthsController,
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        label: 'Fortalezas',
                        icon: Icons.star_rounded,
                        hint: '¿Qué está haciendo especialmente bien?',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _areasToImproveController,
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        label: 'Aspectos a mejorar',
                        icon: Icons.trending_up_rounded,
                        hint: '¿En qué aspectos debemos seguir trabajando?',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _observationsController,
                      minLines: 3,
                      maxLines: 7,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        label: 'Observaciones',
                        icon: Icons.notes_rounded,
                        hint: 'Comentarios adicionales del entrenador...',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _FormCard(
                title: 'Estado',
                icon: Icons.fact_check_rounded,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SelectionChip(
                      label: 'Completada',
                      icon: Icons.check_circle_rounded,
                      selected: _status == 'completed',
                      onPressed: () {
                        setState(() {
                          _status = 'completed';
                        });
                      },
                    ),
                    _SelectionChip(
                      label: 'Borrador',
                      icon: Icons.edit_note_rounded,
                      selected: _status == 'draft',
                      onPressed: () {
                        setState(() {
                          _status = 'draft';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveEvaluation,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.fuchsia,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: AppColors.white,
                      ),
                    )
                  : Icon(
                      widget.isEditing
                          ? Icons.save_rounded
                          : Icons.add_chart_rounded,
                    ),
              label: Text(
                _isSaving
                    ? 'GUARDANDO...'
                    : widget.isEditing
                    ? 'GUARDAR CAMBIOS'
                    : _status == 'draft'
                    ? 'GUARDAR BORRADOR'
                    : 'GUARDAR EVALUACIÓN',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSelector() {
    if (_isLoadingPlayers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.fuchsia),
        ),
      );
    }

    if (_playerError != null) {
      return Column(
        children: [
          Text(
            _playerError!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFC62828),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _loadPlayers,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('REINTENTAR'),
          ),
        ],
      );
    }

    if (_players.isEmpty) {
      return const Text(
        'No hay jugadores registrados para evaluar.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF81747A), fontWeight: FontWeight.w700),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedPlayerId,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Jugador',
        icon: Icons.person_rounded,
      ),
      items: _players.map((_PlayerOption player) {
        return DropdownMenuItem<String>(
          value: player.id,
          child: Text(
            player.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          _selectedPlayerId = value;
        });
      },
      validator: (String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Selecciona un jugador.';
        }

        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.fuchsia),
      filled: true,
      fillColor: const Color(0xFFFAF7F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE8DEE3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE8DEE3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.fuchsia, width: 1.6),
      ),
    );
  }
}

class _PlayerOption {
  const _PlayerOption({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  final String id;
  final String firstName;
  final String lastName;

  String get fullName {
    return '$firstName $lastName'.trim();
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.11)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.fuchsia),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ScoreSelector extends StatelessWidget {
  const _ScoreSelector({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.fuchsia.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.fuchsia),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF81747A),
                        fontSize: 10.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 45,
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$value',
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: List<Widget>.generate(5, (int index) {
              final int score = index + 1;
              final bool selected = value == score;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: score == 5 ? 0 : 6),
                  child: InkWell(
                    onTap: () {
                      onChanged(score);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.fuchsia : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.fuchsia
                              : AppColors.fuchsia.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        '$score',
                        style: TextStyle(
                          color: selected ? AppColors.white : AppColors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AverageCard extends StatelessWidget {
  const _AverageCard({required this.average});

  final double average;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkFuchsia, AppColors.fuchsia],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
            ),
            child: Text(
              average.toStringAsFixed(1),
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promedio general',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Resultado de las cuatro áreas evaluadas.',
                  style: TextStyle(
                    color: Color(0xFFE9DDE3),
                    fontSize: 11,
                    height: 1.3,
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

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        onPressed();
      },
      avatar: Icon(
        icon,
        size: 17,
        color: selected ? AppColors.white : AppColors.fuchsia,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.white : AppColors.black,
          fontWeight: FontWeight.w800,
        ),
      ),
      selectedColor: AppColors.fuchsia,
      backgroundColor: const Color(0xFFF8F3F5),
      side: BorderSide(
        color: selected
            ? AppColors.fuchsia
            : AppColors.fuchsia.withValues(alpha: 0.15),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFAF7F9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8DEE3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.fuchsia),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF81747A),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
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
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');

  final String month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String _statusLabel(String status) {
  switch (status) {
    case 'draft':
      return 'Borrador';

    case 'archived':
      return 'Archivada';

    default:
      return 'Completada';
  }
}
