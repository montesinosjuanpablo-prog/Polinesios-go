import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../training/models/training_group_model.dart';
import '../../training/repositories/training_group_repository.dart';
import '../models/announcement_model.dart';
import '../repositories/announcement_repository.dart';

class AnnouncementFormScreen extends StatefulWidget {
  const AnnouncementFormScreen({this.announcement, super.key});

  final AnnouncementModel? announcement;

  bool get isEditing => announcement != null;

  @override
  State<AnnouncementFormScreen> createState() {
    return _AnnouncementFormScreenState();
  }
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final AnnouncementRepository _repository = const AnnouncementRepository();

  final TrainingGroupRepository _groupRepository =
      const TrainingGroupRepository();

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _messageController = TextEditingController();

  List<TrainingGroupModel> _groups = <TrainingGroupModel>[];

  TrainingGroupModel? _selectedGroup;

  DateTime _publishDate = DateTime.now();
  DateTime _expiresOn = DateTime.now().add(const Duration(days: 7));

  String _priority = 'normal';
  String _audience = 'all';
  String _status = 'published';

  bool _isLoadingGroups = true;
  bool _isSaving = false;

  String? _groupError;

  @override
  void initState() {
    super.initState();

    final AnnouncementModel? announcement = widget.announcement;

    if (announcement != null) {
      _titleController.text = announcement.title;
      _messageController.text = announcement.message;
      _publishDate = announcement.publishDate;
      _expiresOn =
          announcement.expiresOn ??
          announcement.publishDate.add(const Duration(days: 7));
      _priority = announcement.priority;
      _audience = announcement.audience;
      _status = announcement.status;
    }

    _loadGroups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
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

      final String? currentGroupId = widget.announcement?.trainingGroupId;

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
      debugPrint('Error al cargar grupos para comunicado: $error');

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
      initialDate: _publishDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: 'Fecha del comunicado',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _publishDate = selected;

      if (_expiresOn.isBefore(_publishDate)) {
        _expiresOn = _publishDate.add(const Duration(days: 7));
      }
    });
  }

  Future<void> _selectExpiryDate() async {
    final DateTime firstAllowed = DateTime(
      _publishDate.year,
      _publishDate.month,
      _publishDate.day,
    );

    final DateTime initialDate = _expiresOn.isBefore(firstAllowed)
        ? firstAllowed
        : _expiresOn;

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowed,
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: 'Fecha de vencimiento',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _expiresOn = selected;
    });
  }

  Future<void> _saveAnnouncement() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    if (_audience == 'group' && _selectedGroup == null) {
      _showMessage(
        'Selecciona el grupo que recibirá el comunicado.',
        isError: true,
      );
      return;
    }

    final String audienceText = _audience == 'all'
        ? 'Toda la Familia Polinesios'
        : _selectedGroup!.name;

    final DateTime publicationDay = DateTime(
      _publishDate.year,
      _publishDate.month,
      _publishDate.day,
    );

    final DateTime expiryDay = DateTime(
      _expiresOn.year,
      _expiresOn.month,
      _expiresOn.day,
    );

    if (expiryDay.isBefore(publicationDay)) {
      _showMessage(
        'La fecha de vencimiento no puede ser anterior '
        'a la fecha de publicación.',
        isError: true,
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            widget.isEditing ? 'Guardar cambios' : 'Publicar comunicado',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleController.text.trim(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text('Prioridad: ${_priorityLabel(_priority)}'),
              const SizedBox(height: 5),
              Text('Destinatarios: $audienceText'),
              const SizedBox(height: 5),
              Text('Publicación: ${_formatDate(_publishDate)}'),
              const SizedBox(height: 5),
              Text('Vencimiento: ${_formatDate(_expiresOn)}'),
              const SizedBox(height: 5),
              Text('Estado: ${_statusLabel(_status)}'),
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
                widget.isEditing
                    ? 'GUARDAR'
                    : _status == 'draft'
                    ? 'GUARDAR BORRADOR'
                    : 'PUBLICAR',
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
      final TrainingGroupModel? group = _selectedGroup;

      final AnnouncementModel announcement = AnnouncementModel(
        id: widget.announcement?.id ?? '',
        schoolId: widget.announcement?.schoolId ?? '',
        trainingGroupId: _audience == 'group' ? group?.id : null,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        priority: _priority,
        audience: _audience,
        publishDate: _publishDate,
        expiresOn: _expiresOn,
        status: _status,
        createdBy: widget.announcement?.createdBy ?? '',
        trainingGroupName: _audience == 'group' ? group?.name ?? '' : '',
      );

      final AnnouncementModel saved;

      if (widget.isEditing) {
        saved = await _repository.updateAnnouncement(announcement);
      } else {
        saved = await _repository.createAnnouncement(announcement);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<AnnouncementModel>(saved);
    } catch (error) {
      debugPrint('Error al guardar comunicado: $error');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F4),
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        title: Text(
          widget.isEditing ? 'Editar comunicado' : 'Nuevo comunicado',
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
                title: 'Comunicado',
                icon: Icons.campaign_rounded,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        label: 'Título',
                        icon: Icons.title_rounded,
                        hint: 'Ej. Jornada de confraternización',
                      ),
                      validator: (String? value) {
                        final String text = value?.trim() ?? '';

                        if (text.length < 3) {
                          return 'Ingresa un título válido.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      minLines: 5,
                      maxLines: 10,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        label: 'Mensaje',
                        icon: Icons.notes_rounded,
                        hint: 'Escribe el comunicado...',
                      ),
                      validator: (String? value) {
                        final String text = value?.trim() ?? '';

                        if (text.length < 3) {
                          return 'Escribe el contenido del comunicado.';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _FormCard(
                title: 'Prioridad',
                icon: Icons.flag_rounded,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SelectionChip(
                      label: 'Normal',
                      icon: Icons.campaign_rounded,
                      selected: _priority == 'normal',
                      onPressed: () {
                        setState(() {
                          _priority = 'normal';
                        });
                      },
                    ),
                    _SelectionChip(
                      label: 'Importante',
                      icon: Icons.priority_high_rounded,
                      selected: _priority == 'important',
                      onPressed: () {
                        setState(() {
                          _priority = 'important';
                        });
                      },
                    ),
                    _SelectionChip(
                      label: 'Urgente',
                      icon: Icons.warning_amber_rounded,
                      selected: _priority == 'urgent',
                      onPressed: () {
                        setState(() {
                          _priority = 'urgent';
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _FormCard(
                title: 'Destinatarios',
                icon: Icons.people_alt_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SelectionChip(
                          label: 'Toda la Familia Polinesios',
                          icon: Icons.groups_rounded,
                          selected: _audience == 'all',
                          onPressed: () {
                            setState(() {
                              _audience = 'all';
                              _selectedGroup = null;
                            });
                          },
                        ),
                        _SelectionChip(
                          label: 'Grupo específico',
                          icon: Icons.group_work_rounded,
                          selected: _audience == 'group',
                          onPressed: () {
                            setState(() {
                              _audience = 'group';
                            });
                          },
                        ),
                      ],
                    ),

                    if (_audience == 'group') ...[
                      const SizedBox(height: 16),

                      if (_isLoadingGroups)
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.fuchsia,
                          ),
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
                            label: 'Grupo destinatario',
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
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _FormCard(
                title: 'Publicación',
                icon: Icons.event_rounded,
                child: Column(
                  children: [
                    _PickerField(
                      label: 'Fecha de publicación',
                      value: _formatDate(_publishDate),
                      icon: Icons.calendar_month_rounded,
                      onPressed: _selectDate,
                    ),
                    const SizedBox(height: 14),
                    _PickerField(
                      label: 'Fecha de vencimiento',
                      value: _formatDate(_expiresOn),
                      icon: Icons.event_busy_rounded,
                      onPressed: _selectExpiryDate,
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Estado',
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
                        _SelectionChip(
                          label: 'Publicado',
                          icon: Icons.visibility_rounded,
                          selected: _status == 'published',
                          onPressed: () {
                            setState(() {
                              _status = 'published';
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
              onPressed: _isSaving ? null : _saveAnnouncement,
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
                          : Icons.campaign_rounded,
                    ),
              label: Text(
                _isSaving
                    ? 'GUARDANDO...'
                    : widget.isEditing
                    ? 'GUARDAR CAMBIOS'
                    : _status == 'draft'
                    ? 'GUARDAR BORRADOR'
                    : 'PUBLICAR COMUNICADO',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
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

  static String _priorityLabel(String priority) {
    switch (priority) {
      case 'important':
        return 'Importante';

      case 'urgent':
        return 'Urgente';

      default:
        return 'Normal';
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Borrador';

      case 'archived':
        return 'Archivado';

      default:
        return 'Publicado';
    }
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
