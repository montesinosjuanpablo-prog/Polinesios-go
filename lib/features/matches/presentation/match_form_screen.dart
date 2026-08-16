import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../training/models/training_group_model.dart';
import '../../training/repositories/training_group_repository.dart';
import '../models/match_model.dart';
import '../repositories/match_repository.dart';

class MatchFormScreen extends StatefulWidget {
  const MatchFormScreen({this.match, this.isRescheduling = false, super.key});

  final MatchModel? match;

  /// Cuando es true, estamos modificando un partido
  /// para volverlo a dejar en estado PROGRAMADO.
  final bool isRescheduling;

  bool get isEditing => match != null;

  @override
  State<MatchFormScreen> createState() {
    return _MatchFormScreenState();
  }
}

class _MatchFormScreenState extends State<MatchFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final MatchRepository _repository = const MatchRepository();

  final TrainingGroupRepository _groupRepository =
      const TrainingGroupRepository();

  final TextEditingController _opponentController = TextEditingController();

  final TextEditingController _notesController = TextEditingController();

  List<TrainingGroupModel> _groups = <TrainingGroupModel>[];

  TrainingGroupModel? _selectedGroup;

  DateTime _selectedDate = DateTime.now();

  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  String _homeAway = 'home';

  bool _isLoadingGroups = true;
  bool _isSaving = false;

  String? _groupError;

  @override
  void initState() {
    super.initState();

    final MatchModel? match = widget.match;

    if (match != null) {
      _opponentController.text = match.opponentName;

      _notesController.text = match.notes;

      _selectedDate = match.matchDate;

      _selectedTime = _timeFromDatabase(match.startTime);

      _homeAway = match.homeAway;
    }

    _loadGroups();
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoadingGroups = true;
      _groupError = null;
    });

    try {
      final List<TrainingGroupModel> groups = await _groupRepository
          .getActiveGroups();

      TrainingGroupModel? selected;

      final String? currentGroupId = widget.match?.trainingGroupId;

      if (currentGroupId != null && currentGroupId.isNotEmpty) {
        for (final TrainingGroupModel group in groups) {
          if (group.id == currentGroupId) {
            selected = group;
            break;
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _groups = groups;
        _selectedGroup = selected;
        _isLoadingGroups = false;
      });
    } catch (error) {
      debugPrint('Error al cargar grupos: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingGroups = false;
        _groupError = 'No fue posible cargar los grupos.';
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: 'Selecciona la fecha',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = selected;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Selecciona la hora',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = selected;
    });
  }

  Future<void> _saveMatch() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final TrainingGroupModel? group = _selectedGroup;

    if (group == null) {
      _showMessage('Selecciona un grupo.', isError: true);
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            widget.isRescheduling
                ? 'Reprogramar partido'
                : widget.isEditing
                ? 'Guardar cambios'
                : 'Crear partido',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _matchPreviewTitle(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(group.name),
              const SizedBox(height: 5),
              Text(_formatDate(_selectedDate)),
              const SizedBox(height: 5),
              Text(_selectedTime.format(context)),
              const SizedBox(height: 5),
              Text(
                group.locationName.trim().isEmpty
                    ? 'Lugar no registrado'
                    : group.locationName,
              ),
              if (widget.isRescheduling) ...[
                const SizedBox(height: 12),
                const Text(
                  'El partido volverá a quedar como PROGRAMADO.',
                  style: TextStyle(
                    color: AppColors.fuchsia,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('CANCELAR'),
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
                widget.isRescheduling
                    ? 'REPROGRAMAR'
                    : widget.isEditing
                    ? 'GUARDAR'
                    : 'CREAR',
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
      final MatchModel match = MatchModel(
        id: widget.match?.id ?? '',
        schoolId: widget.match?.schoolId ?? '',
        trainingGroupId: group.id,
        locationId: group.locationId.isEmpty ? null : group.locationId,
        opponentName: _opponentController.text.trim(),
        matchDate: _selectedDate,
        startTime: _timeForDatabase(_selectedTime),
        homeAway: _homeAway,

        // CLAVE:
        // si estamos reprogramando, vuelve
        // automáticamente a PROGRAMADO.
        status: widget.isRescheduling
            ? 'scheduled'
            : widget.match?.status ?? 'scheduled',

        // Una reprogramación representa un
        // nuevo partido pendiente, por eso
        // quitamos un resultado anterior.
        goalsFor: widget.isRescheduling ? null : widget.match?.goalsFor,
        goalsAgainst: widget.isRescheduling ? null : widget.match?.goalsAgainst,

        notes: _notesController.text.trim(),
        createdBy: widget.match?.createdBy ?? '',
        trainingGroupName: group.name,
        locationName: group.locationName,
      );

      final MatchModel saved;

      if (widget.isEditing) {
        saved = await _repository.updateMatch(match);
      } else {
        saved = await _repository.createMatch(match);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<MatchModel>(saved);
    } catch (error) {
      debugPrint('Error al guardar partido: $error');

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

  String _matchPreviewTitle() {
    final String opponent = _opponentController.text.trim();

    if (_homeAway == 'away') {
      return '$opponent vs Polinesios';
    }

    return 'Polinesios vs $opponent';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        title: Text(
          widget.isRescheduling
              ? 'Reprogramar partido'
              : widget.isEditing
              ? 'Editar partido'
              : 'Nuevo partido',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
            children: [
              if (widget.isRescheduling) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.event_repeat_rounded,
                        color: AppColors.fuchsia,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Modifica los datos necesarios. Al guardar, el partido quedará nuevamente programado.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              _buildMainCard(),
              const SizedBox(height: 16),
              _buildNotesCard(),
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
              onPressed: _isSaving ? null : _saveMatch,
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
                      widget.isRescheduling
                          ? Icons.event_repeat_rounded
                          : widget.isEditing
                          ? Icons.save_rounded
                          : Icons.sports_soccer_rounded,
                    ),
              label: Text(
                _isSaving
                    ? 'GUARDANDO...'
                    : widget.isRescheduling
                    ? 'GUARDAR REPROGRAMACIÓN'
                    : widget.isEditing
                    ? 'GUARDAR CAMBIOS'
                    : 'CREAR PARTIDO',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return _FormCard(
      title: 'Datos del partido',
      icon: Icons.sports_soccer_rounded,
      child: Column(
        children: [
          TextFormField(
            controller: _opponentController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              label: 'Escuela / equipo rival',
              icon: Icons.shield_outlined,
              hint: 'Ej. Eva Perón',
            ),
            validator: (String? value) {
              final String text = value?.trim() ?? '';

              if (text.length < 2) {
                return 'Ingresa el nombre del rival.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),

          if (_isLoadingGroups)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: AppColors.fuchsia),
            )
          else if (_groupError != null)
            Column(
              children: [
                Text(
                  _groupError!,
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _loadGroups,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('REINTENTAR'),
                ),
              ],
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedGroup?.id,
              isExpanded: true,
              decoration: _inputDecoration(
                label: 'Grupo / categoría',
                icon: Icons.groups_rounded,
              ),
              items: _groups.map((TrainingGroupModel group) {
                return DropdownMenuItem<String>(
                  value: group.id,
                  child: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }

                TrainingGroupModel? selected;

                for (final TrainingGroupModel group in _groups) {
                  if (group.id == value) {
                    selected = group;
                    break;
                  }
                }

                setState(() {
                  _selectedGroup = selected;
                });
              },
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Selecciona un grupo.';
                }

                return null;
              },
            ),

          if (_selectedGroup != null) ...[
            const SizedBox(height: 10),
            _GroupInformation(group: _selectedGroup!),
          ],

          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool narrow = constraints.maxWidth < 420;

              if (narrow) {
                return Column(
                  children: [
                    _PickerField(
                      label: 'Fecha',
                      value: _formatDate(_selectedDate),
                      icon: Icons.calendar_month_rounded,
                      onPressed: _selectDate,
                    ),
                    const SizedBox(height: 12),
                    _PickerField(
                      label: 'Hora',
                      value: _selectedTime.format(context),
                      icon: Icons.schedule_rounded,
                      onPressed: _selectTime,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _PickerField(
                      label: 'Fecha',
                      value: _formatDate(_selectedDate),
                      icon: Icons.calendar_month_rounded,
                      onPressed: _selectDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerField(
                      label: 'Hora',
                      value: _selectedTime.format(context),
                      icon: Icons.schedule_rounded,
                      onPressed: _selectTime,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Condición',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 9),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HomeAwayOption(
                label: 'Local',
                icon: Icons.home_rounded,
                selected: _homeAway == 'home',
                onPressed: () {
                  setState(() {
                    _homeAway = 'home';
                  });
                },
              ),
              _HomeAwayOption(
                label: 'Visitante',
                icon: Icons.flight_takeoff_rounded,
                selected: _homeAway == 'away',
                onPressed: () {
                  setState(() {
                    _homeAway = 'away';
                  });
                },
              ),
              _HomeAwayOption(
                label: 'Neutral',
                icon: Icons.balance_rounded,
                selected: _homeAway == 'neutral',
                onPressed: () {
                  setState(() {
                    _homeAway = 'neutral';
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _FormCard(
      title: 'Observaciones',
      icon: Icons.notes_rounded,
      child: TextFormField(
        controller: _notesController,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        decoration: _inputDecoration(
          label: 'Notas',
          icon: Icons.edit_note_rounded,
          hint: 'Información adicional del partido...',
        ),
      ),
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

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static String _timeForDatabase(TimeOfDay time) {
    final String hour = time.hour.toString().padLeft(2, '0');

    final String minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
  }

  static TimeOfDay _timeFromDatabase(String value) {
    if (value.trim().isEmpty) {
      return const TimeOfDay(hour: 9, minute: 0);
    }

    final List<String> parts = value.split(':');

    if (parts.length < 2) {
      return const TimeOfDay(hour: 9, minute: 0);
    }

    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
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

class _GroupInformation extends StatelessWidget {
  const _GroupInformation({required this.group});

  final TrainingGroupModel group;

  @override
  Widget build(BuildContext context) {
    final String location = group.locationName.trim().isEmpty
        ? 'Lugar no registrado'
        : group.locationName;

    final String coach = group.coachName.trim().isEmpty
        ? 'Entrenador no registrado'
        : group.coachName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fuchsia.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 7,
        children: [
          _MiniInformation(icon: Icons.location_on_rounded, text: location),
          _MiniInformation(icon: Icons.person_rounded, text: coach),
        ],
      ),
    );
  }
}

class _MiniInformation extends StatelessWidget {
  const _MiniInformation({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.fuchsia),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF665A60),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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

class _HomeAwayOption extends StatelessWidget {
  const _HomeAwayOption({
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
