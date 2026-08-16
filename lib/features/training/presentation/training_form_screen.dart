import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/training_group_model.dart';
import '../models/training_session_model.dart';
import '../repositories/training_group_repository.dart';
import '../repositories/training_repository.dart';
import 'widgets/training_group_dropdown.dart';

class TrainingFormScreen extends StatefulWidget {
  const TrainingFormScreen({this.session, super.key});

  final TrainingSessionModel? session;

  bool get isEditing => session != null;

  @override
  State<TrainingFormScreen> createState() {
    return _TrainingFormScreenState();
  }
}

class _TrainingFormScreenState extends State<TrainingFormScreen> {
  final TrainingRepository _repository = const TrainingRepository();

  final TrainingGroupRepository _groupRepository =
      const TrainingGroupRepository();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _objectiveController = TextEditingController();

  final TextEditingController _materialsController = TextEditingController();

  final TextEditingController _notesController = TextEditingController();

  List<TrainingGroupModel> _groups = <TrainingGroupModel>[];

  TrainingGroupModel? _selectedGroup;

  DateTime _selectedDate = DateTime.now();

  TimeOfDay _startTime = const TimeOfDay(hour: 14, minute: 30);

  TimeOfDay _endTime = const TimeOfDay(hour: 16, minute: 0);

  bool _isLoadingGroups = true;
  bool _isSaving = false;

  String? _groupsError;

  @override
  void initState() {
    super.initState();

    final TrainingSessionModel? session = widget.session;

    if (session != null) {
      _selectedDate = session.date;
      _startTime = _timeFromDatabase(session.startTime);
      _endTime = _timeFromDatabase(session.endTime);

      _objectiveController.text = session.objective;
      _materialsController.text = session.materials;
      _notesController.text = session.notes;
    }

    _loadGroups();
  }

  @override
  void dispose() {
    _objectiveController.dispose();
    _materialsController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoadingGroups = true;
      _groupsError = null;
    });

    try {
      final List<TrainingGroupModel> groups = await _groupRepository
          .getActiveGroups();

      if (!mounted) {
        return;
      }

      setState(() {
        _groups = groups;

        final String? trainingGroupId = widget.session?.trainingGroupId;

        if (trainingGroupId != null) {
          for (final TrainingGroupModel group in groups) {
            if (group.id == trainingGroupId) {
              _selectedGroup = group;
              _startTime = _timeFromDatabase(group.startTime);
              _endTime = _timeFromDatabase(group.endTime);
              break;
            }
          }
        }

        _isLoadingGroups = false;
      });
    } catch (error) {
      debugPrint('Error al cargar grupos de entrenamiento: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingGroups = false;
        _groupsError = 'No fue posible cargar los grupos de entrenamiento.';
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = selected;
    });
  }

  void _selectGroup(TrainingGroupModel? group) {
    if (group == null) {
      return;
    }

    setState(() {
      _selectedGroup = group;

      _startTime = _timeFromDatabase(group.startTime);

      _endTime = _timeFromDatabase(group.endTime);
    });
  }

  Future<void> _saveTraining() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final TrainingGroupModel? group = _selectedGroup;

    if (group == null) {
      _showMessage('Selecciona un grupo de entrenamiento.', isError: true);
      return;
    }

    final int startMinutes = (_startTime.hour * 60) + _startTime.minute;

    final int endMinutes = (_endTime.hour * 60) + _endTime.minute;

    if (endMinutes <= startMinutes) {
      _showMessage('El horario del grupo no es válido.', isError: true);
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            widget.isEditing ? 'Guardar cambios' : 'Crear entrenamiento',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(_formatDate(_selectedDate)),
              const SizedBox(height: 6),
              Text('${_formatTime(_startTime)} - ${_formatTime(_endTime)}'),
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
                widget.isEditing ? 'GUARDAR' : 'CREAR',
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
      final TrainingSessionModel session = TrainingSessionModel(
        id: '',
        trainingGroupId: group.id,
        date: _selectedDate,
        startTime: _timeForDatabase(_startTime),
        endTime: _timeForDatabase(_endTime),

        // La sede/cancha se obtiene automáticamente
        // del grupo seleccionado.
        location: group.locationName,

        // Por ahora utilizamos el nombre del grupo
        // como referencia visual de categoría.
        categoryName: group.name,

        // Todavía no existe una relación formal
        // grupo -> entrenador en Supabase.
        // No usamos created_by porque identifica
        // quién creó el registro, no necesariamente
        // quién dirige el entrenamiento.
        coachName: group.coachName,

        objective: _objectiveController.text.trim(),
        materials: _materialsController.text.trim(),
        notes: _notesController.text.trim(),
        status: 'scheduled',
      );

      final TrainingSessionModel savedSession;

      if (widget.isEditing) {
        final TrainingSessionModel originalSession = widget.session!;

        final TrainingSessionModel updatedSession = session.copyWith(
          id: originalSession.id,
        );

        savedSession = await _repository.updateTrainingSession(updatedSession);
      } else {
        savedSession = await _repository.createTrainingSession(session);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<TrainingSessionModel>(savedSession);
    } catch (error) {
      debugPrint('Error al guardar entrenamiento: $error');

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

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFC62828)
              : AppColors.fuchsia,
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
      backgroundColor: const Color(0xFFF7F3F5),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Editar entrenamiento' : 'Nuevo entrenamiento',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              const _FormIntroduction(),

              const SizedBox(height: 18),

              _SectionCard(
                title: 'Sesión',
                subtitle: 'Selecciona la fecha y el grupo',
                icon: Icons.sports_soccer_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DateSelector(date: _selectedDate, onPressed: _selectDate),

                    const SizedBox(height: 14),

                    TrainingGroupDropdown(
                      groups: _groups,
                      selectedGroup: _selectedGroup,
                      isLoading: _isLoadingGroups,
                      errorMessage: _groupsError,
                      onRetry: _loadGroups,
                      onChanged: _selectGroup,
                    ),

                    if (_selectedGroup != null) ...[
                      const SizedBox(height: 16),
                      _SelectedGroupCard(
                        group: _selectedGroup!,
                        startTime: _startTime,
                        endTime: _endTime,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Planificación',
                subtitle: 'Define el propósito de la sesión',
                icon: Icons.flag_rounded,
                child: Column(
                  children: [
                    _TrainingTextField(
                      controller: _objectiveController,
                      label: 'Objetivo del entrenamiento',
                      icon: Icons.track_changes_rounded,
                      hintText: 'Ej. Pase, conducción y finalización',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 14),

                    _TrainingTextField(
                      controller: _materialsController,
                      label: 'Material necesario',
                      icon: Icons.inventory_2_outlined,
                      hintText: 'Ej. Balones, conos y petos',
                      maxLines: 3,
                      requiredField: false,
                    ),

                    const SizedBox(height: 14),

                    _TrainingTextField(
                      controller: _notesController,
                      label: 'Observaciones',
                      icon: Icons.notes_rounded,
                      hintText: 'Información adicional de la sesión',
                      maxLines: 4,
                      requiredField: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveTraining,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.black,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isSaving
                        ? 'GUARDANDO...'
                        : widget.isEditing
                        ? 'GUARDAR CAMBIOS'
                        : 'CREAR ENTRENAMIENTO',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
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

  static String _formatDate(DateTime date) {
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

    return '${date.day} de '
        '${months[date.month - 1]} '
        'de ${date.year}';
  }

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  static String _timeForDatabase(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
  }

  static TimeOfDay _timeFromDatabase(String value) {
    final List<String> parts = value.split(':');

    if (parts.length < 2) {
      return const TimeOfDay(hour: 0, minute: 0);
    }

    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }
}

class _FormIntroduction extends StatelessWidget {
  const _FormIntroduction();

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
      ),
      child: const Row(
        children: [
          Icon(Icons.sports_soccer_rounded, color: AppColors.yellow, size: 42),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planifica en segundos',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Selecciona el grupo, define el objetivo y guarda la sesión.',
                  style: TextStyle(
                    color: Colors.white70,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.12)),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.fuchsia.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.fuchsia),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF81747A),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.date, required this.onPressed});

  final DateTime date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F3F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.fuchsia.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event_rounded, color: AppColors.fuchsia),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fecha',
                    style: TextStyle(
                      color: Color(0xFF81747A),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _TrainingFormScreenState._formatDate(date),
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_month_rounded, color: AppColors.fuchsia),
          ],
        ),
      ),
    );
  }
}

class _SelectedGroupCard extends StatelessWidget {
  const _SelectedGroupCard({
    required this.group,
    required this.startTime,
    required this.endTime,
  });

  final TrainingGroupModel group;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.yellow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF168A55),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Grupo seleccionado',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            group.name,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _GroupInformation(
                icon: Icons.schedule_rounded,
                value:
                    '${_TrainingFormScreenState._formatTime(startTime)} - '
                    '${_TrainingFormScreenState._formatTime(endTime)}',
              ),
              _GroupInformation(
                icon: Icons.badge_outlined,
                value: 'Grupo configurado',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupInformation extends StatelessWidget {
  const _GroupInformation({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.fuchsia),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF5F5358),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TrainingTextField extends StatelessWidget {
  const _TrainingTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hintText,
    this.maxLines = 1,
    this.requiredField = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hintText;
  final int maxLines;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (String? value) {
        if (!requiredField) {
          return null;
        }

        if (value == null || value.trim().isEmpty) {
          return 'Este campo es obligatorio.';
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.fuchsia),
        filled: true,
        fillColor: const Color(0xFFF8F3F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.fuchsia.withValues(alpha: 0.10),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.fuchsia, width: 1.5),
        ),
      ),
    );
  }
}
