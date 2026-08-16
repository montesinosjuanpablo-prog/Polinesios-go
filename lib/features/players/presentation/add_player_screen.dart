import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/player_form_controller.dart';

class AddPlayerScreen extends StatefulWidget {
  const AddPlayerScreen({super.key, this.playerId});

  final String? playerId;

  bool get isEditing {
    final String id = playerId?.trim() ?? '';
    return id.isNotEmpty;
  }

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  late final PlayerFormController _controller;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _controller = PlayerFormController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.loadSportsOptions();

      if (widget.isEditing) {
        await _controller.loadPlayerForEditing(widget.playerId!);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickPlayerPhoto(ImageSource source) async {
    try {
      final XFile? selectedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (selectedFile == null) {
        return;
      }

      final bytes = await selectedFile.readAsBytes();

      if (bytes.isEmpty) {
        _showMessage(
          'No fue posible leer la fotografía seleccionada.',
          isError: true,
        );
        return;
      }

      _controller.setSelectedPhoto(bytes: bytes, fileName: selectedFile.name);
    } catch (error) {
      debugPrint('Error al seleccionar fotografía: $error');

      if (!mounted) {
        return;
      }

      _showMessage('No fue posible seleccionar la fotografía.', isError: true);
    }
  }

  Future<void> _showPhotoSourceSheet() async {
    if (_controller.isSaving) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Fotografía del jugador',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona cómo deseas agregar la fotografía.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF756970)),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF5E7EF),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.fuchsia,
                    ),
                  ),
                  title: const Text(
                    'Elegir de la galería',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickPlayerPhoto(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF5E7EF),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      color: AppColors.fuchsia,
                    ),
                  ),
                  title: const Text(
                    'Tomar fotografía',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickPlayerPhoto(ImageSource.camera);
                  },
                ),
                if (_controller.hasSelectedPhoto)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFEBEE),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                    ),
                    title: const Text(
                      'Quitar fotografía',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _controller.clearSelectedPhoto();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectBirthDate() async {
    final DateTime now = DateTime.now();

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate:
          _controller.birthDate ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(2005),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
      cancelText: 'CANCELAR',
      confirmText: 'SELECCIONAR',
    );

    if (selectedDate != null) {
      _controller.setBirthDate(selectedDate);
    }
  }

  Future<void> _selectRegistrationDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _controller.registrationDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Fecha de inscripción',
      cancelText: 'CANCELAR',
      confirmText: 'SELECCIONAR',
    );

    if (selectedDate != null) {
      _controller.setRegistrationDate(selectedDate);
    }
  }

  void _continueForm() {
    FocusScope.of(context).unfocus();

    if (_controller.isLastStep) {
      _finishForm();
      return;
    }

    final bool advanced = _controller.nextStep();

    if (!advanced) {
      _showMessage(
        'Revisa los campos obligatorios antes de continuar.',
        isError: true,
      );
    }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    _controller.previousStep();
  }

  Future<void> _finishForm() async {
    FocusScope.of(context).unfocus();

    final bool isValid = _controller.validateCurrentStep();

    if (!isValid) {
      _showMessage(
        'Completa correctamente los datos del tutor.',
        isError: true,
      );
      return;
    }

    final bool saved = await _controller.savePlayer();

    if (!mounted) {
      return;
    }

    if (!saved) {
      _showMessage(
        _controller.errorMessage ?? 'No fue posible registrar al jugador.',
        isError: true,
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : AppColors.fuchsia,
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

  Future<bool> _confirmExit() async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('¿Salir del registro?'),
          content: const Text(
            'Los datos introducidos todavía no fueron '
            'guardados y se perderán.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('CONTINUAR'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('SALIR'),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
  }

  Future<void> _closeScreen() async {
    final bool shouldExit = await _confirmExit();

    if (!mounted || !shouldExit) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        if (_controller.isLoadingPlayer) {
          return const Scaffold(
            backgroundColor: Color(0xFFF6F2F4),
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.fuchsia),
                    SizedBox(height: 18),
                    Text(
                      'Cargando ficha del jugador...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.fuchsia,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (!didPop) {
              await _closeScreen();
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF6F2F4),
            appBar: AppBar(
              backgroundColor: AppColors.darkFuchsia,
              foregroundColor: AppColors.white,
              elevation: 0,
              leading: IconButton(
                onPressed: _controller.isSaving ? null : _closeScreen,
                tooltip: 'Cerrar',
                icon: const Icon(Icons.close_rounded),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEditing ? 'Editar jugador' : 'Nuevo jugador',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    widget.isEditing
                        ? 'Actualización de la ficha'
                        : 'Ficha de inscripción',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  _FormProgress(currentStep: _controller.currentStep),
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(
                          context,
                        ).colorScheme.copyWith(primary: AppColors.fuchsia),
                      ),
                      child: Stepper(
                        key: ValueKey<int>(_controller.currentStep),
                        type: StepperType.vertical,
                        currentStep: _controller.currentStep,
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        onStepTapped: _controller.goToStep,
                        onStepContinue: _continueForm,
                        onStepCancel: _previousStep,
                        controlsBuilder:
                            (BuildContext context, ControlsDetails details) {
                              return _FormControls(
                                isFirstStep: _controller.isFirstStep,
                                isLastStep: _controller.isLastStep,
                                isSaving: _controller.isSaving,
                                onPrevious: details.onStepCancel,
                                onContinue: details.onStepContinue,
                              );
                            },
                        steps: [
                          Step(
                            title: const SizedBox.shrink(),
                            isActive: _controller.currentStep >= 0,
                            state: _stepState(0),
                            content: _PersonalStep(
                              controller: _controller,
                              onBirthDatePressed: _selectBirthDate,
                              onPhotoPressed: _showPhotoSourceSheet,
                            ),
                          ),
                          Step(
                            title: const SizedBox.shrink(),
                            isActive: _controller.currentStep >= 1,
                            state: _stepState(1),
                            content: _SportsStep(
                              controller: _controller,
                              onRegistrationDatePressed:
                                  _selectRegistrationDate,
                            ),
                          ),
                          Step(
                            title: const SizedBox.shrink(),
                            isActive: _controller.currentStep >= 2,
                            state: _stepState(2),
                            content: _MedicalStep(controller: _controller),
                          ),
                          Step(
                            title: const SizedBox.shrink(),
                            isActive: _controller.currentStep >= 3,
                            state: _stepState(3),
                            content: _GuardianStep(controller: _controller),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  StepState _stepState(int step) {
    if (_controller.currentStep > step) {
      return StepState.complete;
    }

    if (_controller.currentStep == step) {
      return StepState.editing;
    }

    return StepState.indexed;
  }
}

class _FormProgress extends StatelessWidget {
  const _FormProgress({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final double progress = (currentStep + 1) / PlayerFormController.totalSteps;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkFuchsia, AppColors.fuchsia],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Paso ${currentStep + 1} de '
                '${PlayerFormController.totalSteps}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.yellow,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalStep extends StatelessWidget {
  const _PersonalStep({
    required this.controller,
    required this.onBirthDatePressed,
    required this.onPhotoPressed,
  });

  final PlayerFormController controller;
  final VoidCallback onBirthDatePressed;
  final VoidCallback onPhotoPressed;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.personalFormKey,
      child: _FormSection(
        icon: Icons.person_rounded,
        title: 'Datos personales',
        subtitle: 'Información de identificación del jugador.',
        children: [
          _PlayerPhotoPlaceholder(
            initials: _initials(
              controller.firstNameController.text,
              controller.lastNameController.text,
            ),
            photoBytes: controller.photoBytes,
            onPhotoPressed: onPhotoPressed,
            hasSelectedPhoto: controller.hasSelectedPhoto,
          ),
          _ResponsiveFields(
            children: [
              TextFormField(
                controller: controller.playerCodeController,
                validator: (String? value) {
                  return controller.validateRequiredText(
                    value,
                    'el código del jugador',
                  );
                },
                decoration: _decoration(
                  label: 'Código interno *',
                  icon: Icons.tag_rounded,
                  hint: 'POL-001',
                ),
              ),
              TextFormField(
                controller: controller.firstNameController,
                validator: (String? value) {
                  return controller.validateRequiredText(value, 'los nombres');
                },
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(
                  label: 'Nombres *',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              TextFormField(
                controller: controller.lastNameController,
                validator: (String? value) {
                  return controller.validateRequiredText(
                    value,
                    'los apellidos',
                  );
                },
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(
                  label: 'Apellidos *',
                  icon: Icons.badge_outlined,
                ),
              ),
              TextFormField(
                controller: controller.ciController,
                keyboardType: TextInputType.number,
                decoration: _decoration(
                  label: 'Carnet de identidad',
                  icon: Icons.credit_card_rounded,
                ),
              ),
              _DateField(
                label: 'Fecha de nacimiento *',
                value: controller.birthDate,
                icon: Icons.cake_outlined,
                onPressed: onBirthDatePressed,
              ),
              DropdownButtonFormField<String>(
                initialValue: controller.gender,
                decoration: _decoration(label: 'Sexo', icon: Icons.wc_rounded),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Masculino')),
                  DropdownMenuItem(value: 'female', child: Text('Femenino')),
                  DropdownMenuItem(value: 'other', child: Text('Otro')),
                ],
                onChanged: controller.setGender,
              ),
              TextFormField(
                controller: controller.addressController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  label: 'Dirección',
                  icon: Icons.home_outlined,
                ),
              ),
              TextFormField(
                controller: controller.schoolNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(
                  label: 'Unidad educativa',
                  icon: Icons.school_outlined,
                ),
              ),
            ],
          ),
          if (controller.calculatedAge != null)
            _InformationMessage(
              icon: Icons.auto_awesome_rounded,
              text:
                  'Edad calculada: '
                  '${controller.calculatedAge} años.',
            ),
        ],
      ),
    );
  }

  String _initials(String firstName, String lastName) {
    final String first = firstName.trim();
    final String last = lastName.trim();

    return '${first.isEmpty ? '' : first[0]}'
            '${last.isEmpty ? '' : last[0]}'
        .toUpperCase();
  }
}

class _SportsStep extends StatelessWidget {
  const _SportsStep({
    required this.controller,
    required this.onRegistrationDatePressed,
  });

  final PlayerFormController controller;
  final VoidCallback onRegistrationDatePressed;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = controller.categories;
    final List<Map<String, dynamic>> groups = controller.filteredTrainingGroups;

    final String? selectedCategoryId = _validSelectedId(
      controller.categoryId,
      categories,
    );

    final String? selectedTrainingGroupId = _validSelectedId(
      controller.trainingGroupId,
      groups,
    );

    return Form(
      key: controller.sportsFormKey,
      child: _FormSection(
        icon: Icons.sports_soccer_rounded,
        title: 'Información deportiva',
        subtitle: 'Características deportivas y asignación.',
        children: [
          if (controller.isLoadingSportsOptions)
            const _InformationMessage(
              icon: Icons.sync_rounded,
              text: 'Cargando categorías y grupos de entrenamiento...',
            )
          else if (categories.isEmpty)
            const _InformationMessage(
              icon: Icons.warning_amber_rounded,
              text:
                  'No existen categorías activas disponibles. '
                  'Revisa la configuración en Supabase.',
            )
          else
            _ResponsiveFields(
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey<String?>('category-$selectedCategoryId'),
                  initialValue: selectedCategoryId,
                  isExpanded: true,
                  decoration: _decoration(
                    label: 'Categoría *',
                    icon: Icons.category_outlined,
                  ),
                  validator: (String? value) {
                    final String normalized = value?.trim() ?? '';

                    if (normalized.isEmpty) {
                      return 'Selecciona una categoría';
                    }

                    return null;
                  },
                  items: categories.map((Map<String, dynamic> category) {
                    final String id = category['id']?.toString().trim() ?? '';

                    final String name =
                        category['name']?.toString().trim() ??
                        'Categoría sin nombre';

                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: controller.setCategoryId,
                ),

                DropdownButtonFormField<String>(
                  key: ValueKey<String>(
                    'group-${selectedCategoryId ?? 'none'}-'
                    '${selectedTrainingGroupId ?? 'none'}',
                  ),
                  initialValue: selectedTrainingGroupId,
                  isExpanded: true,
                  decoration: _decoration(
                    label: 'Grupo de entrenamiento *',
                    icon: Icons.groups_rounded,
                  ),
                  validator: (String? value) {
                    final String normalized = value?.trim() ?? '';

                    if (normalized.isEmpty) {
                      return 'Selecciona un grupo de entrenamiento';
                    }

                    return null;
                  },
                  items: groups.map((Map<String, dynamic> group) {
                    final String id = group['id']?.toString().trim() ?? '';

                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(
                        _trainingGroupLabel(group),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: selectedCategoryId == null || groups.isEmpty
                      ? null
                      : controller.setTrainingGroupId,
                ),
              ],
            ),
          if (!controller.isLoadingSportsOptions &&
              selectedCategoryId != null &&
              groups.isEmpty)
            const _InformationMessage(
              icon: Icons.info_outline_rounded,
              text:
                  'La categoría seleccionada no tiene grupos '
                  'de entrenamiento activos.',
            ),
          _ResponsiveFields(
            children: [
              TextFormField(
                controller: controller.primaryPositionController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(
                  label: 'Posición principal',
                  icon: Icons.sports_soccer_rounded,
                  hint: 'Delantero',
                ),
              ),
              TextFormField(
                controller: controller.secondaryPositionController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(
                  label: 'Posición secundaria',
                  icon: Icons.swap_horiz_rounded,
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: controller.dominantFoot,
                decoration: _decoration(
                  label: 'Pie dominante',
                  icon: Icons.directions_run_rounded,
                ),
                items: const [
                  DropdownMenuItem(value: 'right', child: Text('Derecho')),
                  DropdownMenuItem(value: 'left', child: Text('Izquierdo')),
                  DropdownMenuItem(value: 'both', child: Text('Ambos')),
                ],
                onChanged: controller.setDominantFoot,
              ),
              TextFormField(
                controller: controller.heightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (String? value) {
                  return controller.validatePositiveNumber(
                    value,
                    'la estatura',
                  );
                },
                decoration: _decoration(
                  label: 'Estatura (cm)',
                  icon: Icons.height_rounded,
                  hint: '135',
                ),
              ),
              TextFormField(
                controller: controller.weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (String? value) {
                  return controller.validatePositiveNumber(value, 'el peso');
                },
                decoration: _decoration(
                  label: 'Peso (kg)',
                  icon: Icons.monitor_weight_outlined,
                  hint: '32.5',
                ),
              ),
              TextFormField(
                controller: controller.shirtSizeController,
                decoration: _decoration(
                  label: 'Talla de camiseta',
                  icon: Icons.checkroom_rounded,
                ),
              ),
              TextFormField(
                controller: controller.shortsSizeController,
                decoration: _decoration(
                  label: 'Talla de corto',
                  icon: Icons.checkroom_outlined,
                ),
              ),
              TextFormField(
                controller: controller.socksSizeController,
                decoration: _decoration(
                  label: 'Talla de medias',
                  icon: Icons.straighten_rounded,
                ),
              ),
              _DateField(
                label: 'Fecha de inscripción',
                value: controller.registrationDate,
                icon: Icons.event_available_rounded,
                onPressed: onRegistrationDatePressed,
              ),
              DropdownButtonFormField<String>(
                initialValue: controller.status,
                decoration: _decoration(
                  label: 'Estado',
                  icon: Icons.check_circle_outline_rounded,
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Activo')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactivo')),
                  DropdownMenuItem(value: 'withdrawn', child: Text('Retirado')),
                  DropdownMenuItem(
                    value: 'suspended',
                    child: Text('Suspendido'),
                  ),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    controller.setStatus(value);
                  }
                },
              ),
            ],
          ),
          TextFormField(
            controller: controller.sportNotesController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration(
              label: 'Observaciones deportivas',
              icon: Icons.notes_rounded,
            ),
          ),
        ],
      ),
    );
  }

  String? _validSelectedId(
    String? selectedId,
    List<Map<String, dynamic>> items,
  ) {
    final String normalizedId = selectedId?.trim() ?? '';

    if (normalizedId.isEmpty) {
      return null;
    }

    final bool exists = items.any(
      (Map<String, dynamic> item) =>
          item['id']?.toString().trim() == normalizedId,
    );

    return exists ? normalizedId : null;
  }

  String _trainingGroupLabel(Map<String, dynamic> group) {
    String name = group['name']?.toString().trim() ?? 'Grupo sin nombre';

    if (name.startsWith('Polinesios ')) {
      name = name.substring('Polinesios '.length);
    }

    final String start = _shortTime(group['start_time']);
    final String end = _shortTime(group['end_time']);

    if (start.isEmpty && end.isEmpty) {
      return name;
    }

    if (start.isEmpty) {
      return '$name · hasta $end';
    }

    if (end.isEmpty) {
      return '$name · desde $start';
    }

    return '$name · $start–$end';
  }

  String _shortTime(dynamic value) {
    final String text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return '';
    }

    final List<String> parts = text.split(':');

    if (parts.length < 2) {
      return text;
    }

    return '${parts[0]}:${parts[1]}';
  }
}

class _MedicalStep extends StatelessWidget {
  const _MedicalStep({required this.controller});

  final PlayerFormController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.medicalFormKey,
      child: _FormSection(
        icon: Icons.medical_information_rounded,
        title: 'Información médica',
        subtitle: 'Datos importantes para cuidar al jugador.',
        children: [
          _ResponsiveFields(
            children: [
              TextFormField(
                controller: controller.bloodTypeController,
                textCapitalization: TextCapitalization.characters,
                decoration: _decoration(
                  label: 'Tipo de sangre',
                  icon: Icons.bloodtype_outlined,
                  hint: 'O+',
                ),
              ),
              TextFormField(
                controller: controller.medicalInsuranceController,
                decoration: _decoration(
                  label: 'Seguro médico',
                  icon: Icons.health_and_safety_outlined,
                ),
              ),
            ],
          ),
          SwitchListTile.adaptive(
            value: controller.hasAsthma,
            onChanged: controller.setHasAsthma,
            activeThumbColor: AppColors.fuchsia,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: const Text(
              '¿Tiene asma?',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('Activa esta opción si fue diagnosticado.'),
            secondary: const Icon(Icons.air_rounded, color: AppColors.fuchsia),
          ),
          _MedicalTextArea(
            controller: controller.allergiesController,
            label: 'Alergias',
            icon: Icons.warning_amber_rounded,
          ),
          _MedicalTextArea(
            controller: controller.medicationsController,
            label: 'Medicamentos',
            icon: Icons.medication_outlined,
          ),
          _MedicalTextArea(
            controller: controller.previousInjuriesController,
            label: 'Lesiones anteriores',
            icon: Icons.healing_rounded,
          ),
          _MedicalTextArea(
            controller: controller.surgeriesController,
            label: 'Operaciones o cirugías',
            icon: Icons.local_hospital_outlined,
          ),
          _MedicalTextArea(
            controller: controller.medicalConditionsController,
            label: 'Enfermedades o condiciones',
            icon: Icons.monitor_heart_outlined,
          ),
          _MedicalTextArea(
            controller: controller.emergencyNotesController,
            label: 'Observaciones de emergencia',
            icon: Icons.emergency_outlined,
          ),
        ],
      ),
    );
  }
}

class _GuardianStep extends StatelessWidget {
  const _GuardianStep({required this.controller});

  final PlayerFormController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.guardianFormKey,
      child: _FormSection(
        icon: Icons.family_restroom_rounded,
        title: 'Padre, madre o tutor',
        subtitle: 'Contacto responsable del jugador.',
        children: [
          _ResponsiveFields(
            children: [
              TextFormField(
                controller: controller.guardianFirstNameController,
                textCapitalization: TextCapitalization.words,
                validator: (String? value) {
                  return controller.validateRequiredText(
                    value,
                    'los nombres del tutor',
                  );
                },
                decoration: _decoration(
                  label: 'Nombres *',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              TextFormField(
                controller: controller.guardianLastNameController,
                textCapitalization: TextCapitalization.words,
                validator: (String? value) {
                  return controller.validateRequiredText(
                    value,
                    'los apellidos del tutor',
                  );
                },
                decoration: _decoration(
                  label: 'Apellidos *',
                  icon: Icons.badge_outlined,
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: controller.guardianRelationship,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Selecciona el parentesco';
                  }

                  return null;
                },
                decoration: _decoration(
                  label: 'Parentesco *',
                  icon: Icons.family_restroom_rounded,
                ),
                items: const [
                  DropdownMenuItem(value: 'father', child: Text('Padre')),
                  DropdownMenuItem(value: 'mother', child: Text('Madre')),
                  DropdownMenuItem(value: 'guardian', child: Text('Tutor')),
                  DropdownMenuItem(
                    value: 'grandparent',
                    child: Text('Abuelo/a'),
                  ),
                  DropdownMenuItem(value: 'other', child: Text('Otro')),
                ],
                onChanged: controller.setGuardianRelationship,
              ),
              TextFormField(
                controller: controller.guardianCiController,
                keyboardType: TextInputType.number,
                decoration: _decoration(
                  label: 'Carnet de identidad',
                  icon: Icons.credit_card_rounded,
                ),
              ),
              TextFormField(
                controller: controller.guardianPhoneController,
                keyboardType: TextInputType.phone,
                validator: (String? value) {
                  return controller.validatePhone(value, required: true);
                },
                decoration: _decoration(
                  label: 'Teléfono *',
                  icon: Icons.phone_outlined,
                ),
              ),
              TextFormField(
                controller: controller.guardianWhatsAppController,
                keyboardType: TextInputType.phone,
                validator: controller.validatePhone,
                decoration: _decoration(
                  label: 'WhatsApp',
                  icon: Icons.chat_outlined,
                ),
              ),
              TextFormField(
                controller: controller.guardianEmailController,
                keyboardType: TextInputType.emailAddress,
                validator: controller.validateEmail,
                decoration: _decoration(
                  label: 'Correo electrónico',
                  icon: Icons.email_outlined,
                ),
              ),
              TextFormField(
                controller: controller.guardianAddressController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  label: 'Dirección',
                  icon: Icons.home_outlined,
                ),
              ),
            ],
          ),
          SwitchListTile.adaptive(
            value: controller.isPrimaryGuardian,
            onChanged: controller.setIsPrimaryGuardian,
            activeThumbColor: AppColors.fuchsia,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: const Text(
              'Tutor principal',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('Será el contacto principal de la escuela.'),
            secondary: const Icon(Icons.star_rounded, color: AppColors.fuchsia),
          ),
          SwitchListTile.adaptive(
            value: controller.canPickUpPlayer,
            onChanged: controller.setCanPickUpPlayer,
            activeThumbColor: AppColors.fuchsia,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: const Text(
              'Autorizado para recoger al jugador',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              'Indica si puede retirarlo de '
              'entrenamientos y partidos.',
            ),
            secondary: const Icon(
              Icons.verified_user_outlined,
              color: AppColors.fuchsia,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.fuchsia.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.fuchsia),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF776B71),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children.map(
            (Widget child) => Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useColumns = constraints.maxWidth >= 680;

        if (!useColumns) {
          return Column(
            children: children.map((Widget child) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: child,
              );
            }).toList(),
          );
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children.map((Widget child) {
            return SizedBox(
              width: (constraints.maxWidth - 16) / 2,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

class _PlayerPhotoPlaceholder extends StatelessWidget {
  const _PlayerPhotoPlaceholder({
    required this.initials,
    required this.photoBytes,
    required this.onPhotoPressed,
    required this.hasSelectedPhoto,
  });

  final String initials;
  final dynamic photoBytes;
  final VoidCallback onPhotoPressed;
  final bool hasSelectedPhoto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.fuchsia, AppColors.darkFuchsia],
              ),
              border: Border.all(color: AppColors.yellow, width: 4),
            ),
            clipBehavior: Clip.antiAlias,
            child: photoBytes != null
                ? Image.memory(
                    photoBytes,
                    fit: BoxFit.cover,
                    width: 112,
                    height: 112,
                  )
                : Center(
                    child: initials.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            size: 58,
                            color: AppColors.white,
                          )
                        : Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPhotoPressed,
            icon: Icon(
              hasSelectedPhoto
                  ? Icons.edit_rounded
                  : Icons.add_a_photo_outlined,
            ),
            label: Text(
              hasSelectedPhoto ? 'Cambiar fotografía' : 'Agregar fotografía',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            hasSelectedPhoto
                ? 'Fotografía seleccionada. Se guardará al registrar al jugador.'
                : 'La fotografía es opcional.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF84777D), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final DateTime? value;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: _decoration(
          label: label,
          icon: icon,
          suffixIcon: const Icon(Icons.calendar_month_rounded),
        ),
        child: Text(
          value == null ? 'Seleccionar fecha' : _formatDate(value!),
          style: TextStyle(
            color: value == null ? const Color(0xFF8A7D83) : AppColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

class _MedicalTextArea extends StatelessWidget {
  const _MedicalTextArea({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      decoration: _decoration(label: label, icon: icon),
    );
  }
}

class _InformationMessage extends StatelessWidget {
  const _InformationMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fuchsia.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.fuchsia),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF685A61),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormControls extends StatelessWidget {
  const _FormControls({
    required this.isFirstStep,
    required this.isLastStep,
    required this.isSaving,
    required this.onPrevious,
    required this.onContinue,
  });

  final bool isFirstStep;
  final bool isLastStep;
  final bool isSaving;
  final VoidCallback? onPrevious;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: Row(
        children: [
          if (!isFirstStep)
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: isSaving ? null : onPrevious,
                  child: const Icon(Icons.arrow_back_rounded, size: 26),
                ),
              ),
            ),
          if (!isFirstStep) const SizedBox(width: 13),
          Expanded(
            flex: isFirstStep ? 1 : 2,
            child: SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                icon: isSaving
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.black,
                        ),
                      )
                    : Icon(
                        isLastStep
                            ? Icons.save_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                label: Text(
                  isSaving
                      ? 'GUARDANDO...'
                      : isLastStep
                      ? 'GUARDAR JUGADOR'
                      : 'SIGUIENTE',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _decoration({
  required String label,
  required IconData icon,
  String? hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF9F6F8),
    prefixIconColor: AppColors.fuchsia,
    labelStyle: const TextStyle(
      color: Color(0xFF64565D),
      fontWeight: FontWeight.w700,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE8DDE3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.fuchsia, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  );
}
