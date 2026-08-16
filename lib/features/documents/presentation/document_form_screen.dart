import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../models/document_model.dart';
import '../repositories/document_repository.dart';

class DocumentFormScreen extends StatefulWidget {
  const DocumentFormScreen({this.document, super.key});

  final DocumentModel? document;

  bool get isEditing => document != null;

  @override
  State<DocumentFormScreen> createState() {
    return _DocumentFormScreenState();
  }
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final DocumentRepository _repository = const DocumentRepository();

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  SupabaseClient get _client => Supabase.instance.client;

  List<_PlayerOption> _players = <_PlayerOption>[];

  String _scope = 'school';
  String _documentType = 'other';
  String _status = 'active';

  String? _selectedPlayerId;

  DateTime _documentDate = DateTime.now();

  String _schoolId = '';
  String _createdBy = '';

  bool _isLoadingPlayers = true;
  bool _isSaving = false;

  String? _playerError;

  @override
  void initState() {
    super.initState();

    final DocumentModel? document = widget.document;

    if (document != null) {
      _titleController.text = document.title;

      _descriptionController.text = document.description;

      _scope = document.scope;
      _documentType = document.documentType;
      _status = document.status;

      _selectedPlayerId = document.playerId;

      _documentDate = document.documentDate;

      _schoolId = document.schoolId;

      _createdBy = document.createdBy;
    }

    _loadPlayers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

      final String? userId = _client.auth.currentUser?.id;

      if (schoolId == null || schoolId.trim().isEmpty) {
        throw const AuthException(
          'El usuario actual no tiene una escuela asignada.',
        );
      }

      if (userId == null || userId.trim().isEmpty) {
        throw Exception('No fue posible identificar al usuario actual.');
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
          .where((_PlayerOption player) => player.id.trim().isNotEmpty)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _schoolId = schoolId;
        _createdBy = userId;
        _players = players;
        _isLoadingPlayers = false;
      });
    } catch (error) {
      debugPrint('Error al cargar jugadores para documentos: $error');

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
      initialDate: _documentDate,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: 'Fecha del documento',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _documentDate = selected;
    });
  }

  Future<void> _saveDocument() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    if (_scope == 'player' &&
        (_selectedPlayerId == null || _selectedPlayerId!.trim().isEmpty)) {
      _showMessage(
        'Selecciona el jugador al que corresponde el documento.',
        isError: true,
      );
      return;
    }

    _PlayerOption? selectedPlayer;

    if (_scope == 'player') {
      for (final _PlayerOption player in _players) {
        if (player.id == _selectedPlayerId) {
          selectedPlayer = player;
          break;
        }
      }
    }

    final String destination = _scope == 'school'
        ? 'Escuela Formativa Polinesios'
        : selectedPlayer?.fullName ?? 'Jugador';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            widget.isEditing ? 'Guardar cambios' : 'Registrar documento',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleController.text.trim(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text('Tipo: ${_documentTypeLabel(_documentType)}'),
              const SizedBox(height: 5),
              Text('Corresponde a: $destination'),
              const SizedBox(height: 5),
              Text('Fecha: ${_formatDate(_documentDate)}'),
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
                widget.isEditing ? 'GUARDAR' : 'REGISTRAR',
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
      final DocumentModel document = DocumentModel(
        id: widget.document?.id ?? '',
        schoolId: _schoolId,
        playerId: _scope == 'player' ? _selectedPlayerId : null,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        documentType: _documentType,
        scope: _scope,
        documentDate: _documentDate,
        status: _status,
        fileName: widget.document?.fileName,
        filePath: widget.document?.filePath,
        createdBy: _createdBy,
        createdAt: widget.document?.createdAt,
        updatedAt: widget.document?.updatedAt,
        playerName: _scope == 'player' ? selectedPlayer?.fullName ?? '' : '',
        creatorName: widget.document?.creatorName ?? '',
      );

      final DocumentModel saved;

      if (widget.isEditing) {
        saved = await _repository.updateDocument(document);
      } else {
        saved = await _repository.createDocument(document);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<DocumentModel>(saved);
    } catch (error) {
      debugPrint('Error al guardar documento: $error');

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
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.darkFuchsia,
        foregroundColor: AppColors.white,
        title: Text(
          widget.isEditing ? 'Editar documento' : 'Nuevo documento',
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
                title: 'Información del documento',
                icon: Icons.description_rounded,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        label: 'Título',
                        icon: Icons.title_rounded,
                        hint: 'Ej. Autorización para partido',
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
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        label: 'Descripción',
                        icon: Icons.notes_rounded,
                        hint: 'Información o detalle del documento...',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _FormCard(
                title: 'Tipo de documento',
                icon: Icons.category_rounded,
                child: DropdownButtonFormField<String>(
                  initialValue: _documentType,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: 'Tipo',
                    icon: Icons.folder_rounded,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'registration',
                      child: Text('Inscripción'),
                    ),
                    DropdownMenuItem(
                      value: 'identity',
                      child: Text('Identidad'),
                    ),
                    DropdownMenuItem(value: 'medical', child: Text('Médico')),
                    DropdownMenuItem(
                      value: 'authorization',
                      child: Text('Autorización'),
                    ),
                    DropdownMenuItem(
                      value: 'contract',
                      child: Text('Contrato'),
                    ),
                    DropdownMenuItem(value: 'payment', child: Text('Pago')),
                    DropdownMenuItem(
                      value: 'institutional',
                      child: Text('Institucional'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Otro')),
                  ],
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _documentType = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              _FormCard(
                title: 'Corresponde a',
                icon: Icons.groups_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SelectionChip(
                          label: 'Escuela Polinesios',
                          icon: Icons.home_work_rounded,
                          selected: _scope == 'school',
                          onPressed: () {
                            setState(() {
                              _scope = 'school';
                              _selectedPlayerId = null;
                            });
                          },
                        ),
                        _SelectionChip(
                          label: 'Jugador específico',
                          icon: Icons.person_rounded,
                          selected: _scope == 'player',
                          onPressed: () {
                            setState(() {
                              _scope = 'player';
                            });
                          },
                        ),
                      ],
                    ),

                    if (_scope == 'player') ...[
                      const SizedBox(height: 16),
                      _buildPlayerSelector(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _FormCard(
                title: 'Fecha',
                icon: Icons.calendar_month_rounded,
                child: _PickerField(
                  label: 'Fecha del documento',
                  value: _formatDate(_documentDate),
                  icon: Icons.event_rounded,
                  onPressed: _selectDate,
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
              onPressed: _isSaving ? null : _saveDocument,
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
                          : Icons.description_rounded,
                    ),
              label: Text(
                _isSaving
                    ? 'GUARDANDO...'
                    : widget.isEditing
                    ? 'GUARDAR CAMBIOS'
                    : 'GUARDAR DOCUMENTO',
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: CircularProgressIndicator(color: AppColors.fuchsia),
        ),
      );
    }

    if (_playerError != null) {
      return Column(
        children: [
          Text(
            _playerError!,
            style: const TextStyle(
              color: Color(0xFFC62828),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
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
        'No hay jugadores registrados.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF81747A), fontWeight: FontWeight.w700),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedPlayerId,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Jugador',
        icon: Icons.person_search_rounded,
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

  String get fullName => '$firstName $lastName'.trim();
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
      onSelected: (_) => onPressed(),
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

String _documentTypeLabel(String value) {
  switch (value) {
    case 'registration':
      return 'Inscripción';

    case 'identity':
      return 'Identidad';

    case 'medical':
      return 'Médico';

    case 'authorization':
      return 'Autorización';

    case 'contract':
      return 'Contrato';

    case 'payment':
      return 'Pago';

    case 'institutional':
      return 'Institucional';

    default:
      return 'Otro';
  }
}
