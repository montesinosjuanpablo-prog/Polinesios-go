import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/services/storage_service.dart';
import '../data/player_service.dart';
import '../models/player_detail_model.dart';
import '../repositories/player_repository.dart';

class PlayerFormController extends ChangeNotifier {
  PlayerFormController();

  static const int totalSteps = 4;

  final GlobalKey<FormState> personalFormKey = GlobalKey<FormState>();

  final GlobalKey<FormState> sportsFormKey = GlobalKey<FormState>();

  final GlobalKey<FormState> medicalFormKey = GlobalKey<FormState>();

  final GlobalKey<FormState> guardianFormKey = GlobalKey<FormState>();

  final PlayerRepository _repository = const PlayerRepository();
  final StorageService _storageService = const StorageService();

  // =========================================================
  // DATOS PERSONALES
  // =========================================================

  final TextEditingController playerCodeController = TextEditingController();

  final TextEditingController firstNameController = TextEditingController();

  final TextEditingController lastNameController = TextEditingController();

  final TextEditingController ciController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  final TextEditingController schoolNameController = TextEditingController();

  DateTime? _birthDate;
  String? _gender;
  String? _photoUrl;
  Uint8List? _photoBytes;
  String? _photoFileName;

  // =========================================================
  // DATOS DEPORTIVOS
  // =========================================================

  final TextEditingController primaryPositionController =
      TextEditingController();

  final TextEditingController secondaryPositionController =
      TextEditingController();

  final TextEditingController heightController = TextEditingController();

  final TextEditingController weightController = TextEditingController();

  final TextEditingController shirtSizeController = TextEditingController();

  final TextEditingController shortsSizeController = TextEditingController();

  final TextEditingController socksSizeController = TextEditingController();

  final TextEditingController sportNotesController = TextEditingController();

  String? _dominantFoot;
  String? _categoryId;
  String? _trainingGroupId;
  DateTime _registrationDate = DateTime.now();
  String _status = 'active';

  List<Map<String, dynamic>> _categories = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _trainingGroups = <Map<String, dynamic>>[];
  bool _isLoadingSportsOptions = false;

  // =========================================================
  // INFORMACIÓN MÉDICA
  // =========================================================

  final TextEditingController bloodTypeController = TextEditingController();

  final TextEditingController medicalInsuranceController =
      TextEditingController();

  final TextEditingController allergiesController = TextEditingController();

  final TextEditingController medicationsController = TextEditingController();

  final TextEditingController previousInjuriesController =
      TextEditingController();

  final TextEditingController surgeriesController = TextEditingController();

  final TextEditingController medicalConditionsController =
      TextEditingController();

  final TextEditingController emergencyNotesController =
      TextEditingController();

  bool _hasAsthma = false;

  // =========================================================
  // PADRE, MADRE O TUTOR
  // =========================================================

  final TextEditingController guardianFirstNameController =
      TextEditingController();

  final TextEditingController guardianLastNameController =
      TextEditingController();

  final TextEditingController guardianCiController = TextEditingController();

  final TextEditingController guardianPhoneController = TextEditingController();

  final TextEditingController guardianWhatsAppController =
      TextEditingController();

  final TextEditingController guardianEmailController = TextEditingController();

  final TextEditingController guardianAddressController =
      TextEditingController();

  String? _guardianRelationship;
  bool _isPrimaryGuardian = true;
  bool _canPickUpPlayer = true;

  // =========================================================
  // ESTADO DEL FORMULARIO
  // =========================================================

  int _currentStep = 0;
  bool _isSaving = false;
  bool _isLoadingPlayer = false;
  String? _editingPlayerId;
  String? _errorMessage;

  int get currentStep => _currentStep;

  bool get isSaving => _isSaving;

  bool get isLoadingPlayer => _isLoadingPlayer;

  bool get isEditing {
    final String id = _editingPlayerId?.trim() ?? '';
    return id.isNotEmpty;
  }

  String? get editingPlayerId => _editingPlayerId;

  String? get errorMessage => _errorMessage;

  DateTime? get birthDate => _birthDate;

  String? get gender => _gender;

  String? get photoUrl => _photoUrl;

  Uint8List? get photoBytes => _photoBytes;

  String? get photoFileName => _photoFileName;

  bool get hasSelectedPhoto => _photoBytes != null;

  String? get dominantFoot => _dominantFoot;

  String? get categoryId => _categoryId;

  String? get trainingGroupId => _trainingGroupId;

  List<Map<String, dynamic>> get categories =>
      List<Map<String, dynamic>>.unmodifiable(_categories);

  List<Map<String, dynamic>> get trainingGroups =>
      List<Map<String, dynamic>>.unmodifiable(_trainingGroups);

  bool get isLoadingSportsOptions => _isLoadingSportsOptions;

  List<Map<String, dynamic>> get filteredTrainingGroups {
    final String selectedCategoryId = _categoryId?.trim() ?? '';

    if (selectedCategoryId.isEmpty) {
      return List<Map<String, dynamic>>.unmodifiable(_trainingGroups);
    }

    return _trainingGroups
        .where((Map<String, dynamic> group) {
          final String groupCategoryId =
              group['category_id']?.toString().trim() ?? '';

          return groupCategoryId == selectedCategoryId;
        })
        .map((Map<String, dynamic> group) => Map<String, dynamic>.from(group))
        .toList(growable: false);
  }

  DateTime get registrationDate => _registrationDate;

  String get status => _status;

  bool get hasAsthma => _hasAsthma;

  String? get guardianRelationship => _guardianRelationship;

  bool get isPrimaryGuardian => _isPrimaryGuardian;

  bool get canPickUpPlayer => _canPickUpPlayer;

  bool get isFirstStep => _currentStep == 0;

  bool get isLastStep => _currentStep == totalSteps - 1;

  int? get calculatedAge {
    final DateTime? date = _birthDate;

    if (date == null) {
      return null;
    }

    final DateTime today = DateTime.now();
    int age = today.year - date.year;

    final bool birthdayPending =
        today.month < date.month ||
        (today.month == date.month && today.day < date.day);

    if (birthdayPending) {
      age--;
    }

    return age;
  }

  String get fullName {
    return '${firstNameController.text.trim()} '
            '${lastNameController.text.trim()}'
        .trim();
  }

  Future<bool> loadSportsOptions() async {
    _isLoadingSportsOptions = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> results = await Future.wait<dynamic>(
        <Future<dynamic>>[
          PlayerService.getCategories(),
          PlayerService.getTrainingGroups(),
        ],
      );

      _categories = (results[0] as List<Map<String, dynamic>>)
          .map((Map<String, dynamic> item) => Map<String, dynamic>.from(item))
          .toList();

      _trainingGroups = (results[1] as List<Map<String, dynamic>>)
          .map((Map<String, dynamic> item) => Map<String, dynamic>.from(item))
          .toList();

      _normalizeSelectedSportsOptions();

      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      _isLoadingSportsOptions = false;
      notifyListeners();
    }
  }

  Future<bool> loadPlayerForEditing(String playerId) async {
    final String normalizedPlayerId = playerId.trim();

    if (normalizedPlayerId.isEmpty) {
      setError('No fue posible identificar al jugador.');
      return false;
    }

    _isLoadingPlayer = true;
    _editingPlayerId = normalizedPlayerId;
    _errorMessage = null;
    notifyListeners();

    try {
      final PlayerDetailModel detail = await _repository.getPlayerDetailById(
        normalizedPlayerId,
      );

      final player = detail.player;
      final medical = detail.medical;
      final guardian = detail.primaryGuardian;

      playerCodeController.text = player.playerCode;
      firstNameController.text = player.firstName;
      lastNameController.text = player.lastName;
      ciController.text = player.ci ?? '';
      addressController.text = player.address ?? '';
      schoolNameController.text = player.schoolName ?? '';

      _birthDate = player.birthDate;
      _gender = player.gender;
      _photoUrl = player.photoUrl;
      _photoBytes = null;
      _photoFileName = null;

      primaryPositionController.text = player.primaryPosition ?? '';
      secondaryPositionController.text = player.secondaryPosition ?? '';
      heightController.text = _numberToText(player.heightCm);
      weightController.text = _numberToText(player.weightKg);
      shirtSizeController.text = player.shirtSize ?? '';
      shortsSizeController.text = player.shortsSize ?? '';
      socksSizeController.text = player.socksSize ?? '';
      sportNotesController.text = detail.sportNotes ?? '';

      _dominantFoot = player.dominantFoot;
      _categoryId = player.categoryId;
      _trainingGroupId = player.trainingGroupId;
      _normalizeSelectedSportsOptions();
      _registrationDate = player.registrationDate;
      _status = player.status;

      bloodTypeController.text = medical.bloodType ?? '';
      medicalInsuranceController.text = medical.medicalInsurance ?? '';
      allergiesController.text = medical.allergies ?? '';
      medicationsController.text = medical.medications ?? '';
      previousInjuriesController.text = medical.previousInjuries ?? '';
      surgeriesController.text = medical.surgeries ?? '';
      medicalConditionsController.text = medical.medicalConditions ?? '';
      emergencyNotesController.text = medical.emergencyNotes ?? '';
      _hasAsthma = medical.hasAsthma;

      if (guardian != null) {
        guardianFirstNameController.text = guardian.firstName;
        guardianLastNameController.text = guardian.lastName;
        guardianCiController.text = guardian.ci ?? '';
        guardianPhoneController.text = guardian.phone ?? '';
        guardianWhatsAppController.text = guardian.whatsapp ?? '';
        guardianEmailController.text = guardian.email ?? '';
        guardianAddressController.text = guardian.address ?? '';
        _guardianRelationship = _normalizeGuardianRelationship(
          guardian.relationship,
        );
        _isPrimaryGuardian = guardian.isPrimary;
        _canPickUpPlayer = guardian.canPickUp;
      } else {
        guardianFirstNameController.clear();
        guardianLastNameController.clear();
        guardianCiController.clear();
        guardianPhoneController.clear();
        guardianWhatsAppController.clear();
        guardianEmailController.clear();
        guardianAddressController.clear();
        _guardianRelationship = null;
        _isPrimaryGuardian = true;
        _canPickUpPlayer = true;
      }

      _currentStep = 0;
      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      _isLoadingPlayer = false;
      notifyListeners();
    }
  }

  void setBirthDate(DateTime? value) {
    if (_birthDate == value) {
      return;
    }

    _birthDate = value;
    notifyListeners();
  }

  void setGender(String? value) {
    if (_gender == value) {
      return;
    }

    _gender = value;
    notifyListeners();
  }

  void setPhotoUrl(String? value) {
    final String? normalizedValue = _normalizeNullableText(value);

    if (_photoUrl == normalizedValue) {
      return;
    }

    _photoUrl = normalizedValue;
    notifyListeners();
  }

  void setSelectedPhoto({required Uint8List bytes, required String fileName}) {
    if (bytes.isEmpty) {
      return;
    }

    _photoBytes = bytes;
    _photoFileName = fileName.trim().isEmpty
        ? 'player_photo.jpg'
        : fileName.trim();
    notifyListeners();
  }

  void clearSelectedPhoto() {
    _photoBytes = null;
    _photoFileName = null;
    notifyListeners();
  }

  void setDominantFoot(String? value) {
    if (_dominantFoot == value) {
      return;
    }

    _dominantFoot = value;
    notifyListeners();
  }

  void setCategoryId(String? value) {
    final String? normalizedValue = _normalizeNullableText(value);

    if (_categoryId == normalizedValue) {
      return;
    }

    _categoryId = normalizedValue;

    final String selectedTrainingGroupId = _trainingGroupId?.trim() ?? '';

    if (selectedTrainingGroupId.isNotEmpty) {
      final bool groupStillBelongsToCategory = _trainingGroups.any((
        Map<String, dynamic> group,
      ) {
        final String groupId = group['id']?.toString().trim() ?? '';
        final String groupCategoryId =
            group['category_id']?.toString().trim() ?? '';

        return groupId == selectedTrainingGroupId &&
            groupCategoryId == (_categoryId ?? '');
      });

      if (!groupStillBelongsToCategory) {
        _trainingGroupId = null;
      }
    }

    notifyListeners();
  }

  void setTrainingGroupId(String? value) {
    final String? normalizedValue = _normalizeNullableText(value);

    if (_trainingGroupId == normalizedValue) {
      return;
    }

    _trainingGroupId = normalizedValue;

    if (normalizedValue != null) {
      Map<String, dynamic>? selectedGroup;

      for (final Map<String, dynamic> group in _trainingGroups) {
        final String groupId = group['id']?.toString().trim() ?? '';

        if (groupId == normalizedValue) {
          selectedGroup = group;
          break;
        }
      }

      if (selectedGroup != null) {
        _categoryId = _normalizeNullableText(
          selectedGroup['category_id']?.toString(),
        );
      }
    }

    notifyListeners();
  }

  void setRegistrationDate(DateTime value) {
    if (_registrationDate == value) {
      return;
    }

    _registrationDate = value;
    notifyListeners();
  }

  void setStatus(String value) {
    final String normalizedValue = value.trim().toLowerCase();

    if (_status == normalizedValue || normalizedValue.isEmpty) {
      return;
    }

    _status = normalizedValue;
    notifyListeners();
  }

  void setHasAsthma(bool value) {
    if (_hasAsthma == value) {
      return;
    }

    _hasAsthma = value;
    notifyListeners();
  }

  void setGuardianRelationship(String? value) {
    if (_guardianRelationship == value) {
      return;
    }

    _guardianRelationship = value;
    notifyListeners();
  }

  void setIsPrimaryGuardian(bool value) {
    if (_isPrimaryGuardian == value) {
      return;
    }

    _isPrimaryGuardian = value;
    notifyListeners();
  }

  void setCanPickUpPlayer(bool value) {
    if (_canPickUpPlayer == value) {
      return;
    }

    _canPickUpPlayer = value;
    notifyListeners();
  }

  bool validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return personalFormKey.currentState?.validate() ?? false;

      case 1:
        return sportsFormKey.currentState?.validate() ?? false;

      case 2:
        return medicalFormKey.currentState?.validate() ?? false;

      case 3:
        return guardianFormKey.currentState?.validate() ?? false;

      default:
        return false;
    }
  }

  bool nextStep() {
    if (!validateCurrentStep()) {
      return false;
    }

    if (isLastStep) {
      return true;
    }

    _currentStep++;
    _errorMessage = null;
    notifyListeners();

    return true;
  }

  void previousStep() {
    if (isFirstStep || _isSaving) {
      return;
    }

    _currentStep--;
    _errorMessage = null;
    notifyListeners();
  }

  void goToStep(int step) {
    if (step < 0 || step >= totalSteps || step > _currentStep || _isSaving) {
      return;
    }

    _currentStep = step;
    notifyListeners();
  }

  void setSaving(bool value) {
    if (_isSaving == value) {
      return;
    }

    _isSaving = value;
    notifyListeners();
  }

  void setError(String? message) {
    final String? normalizedMessage = _normalizeNullableText(message);

    if (_errorMessage == normalizedMessage) {
      return;
    }

    _errorMessage = normalizedMessage;
    notifyListeners();
  }

  void clearError() {
    setError(null);
  }

  String? validateRequiredText(String? value, String fieldName) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Ingresa $fieldName';
    }

    return null;
  }

  String? validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return null;
    }

    final RegExp pattern = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!pattern.hasMatch(email)) {
      return 'Ingresa un correo válido';
    }

    return null;
  }

  String? validatePhone(String? value, {bool required = false}) {
    final String phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return required ? 'Ingresa un teléfono' : null;
    }

    final String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 7) {
      return 'Ingresa un teléfono válido';
    }

    return null;
  }

  String? validatePositiveNumber(String? value, String fieldName) {
    final String text = value?.trim().replaceAll(',', '.') ?? '';

    if (text.isEmpty) {
      return null;
    }

    final double? number = double.tryParse(text);

    if (number == null || number <= 0) {
      return 'Ingresa un valor válido para $fieldName';
    }

    return null;
  }

  Map<String, dynamic> buildPlayerMap() {
    if (_birthDate == null) {
      throw const FormatException('La fecha de nacimiento es obligatoria.');
    }

    return <String, dynamic>{
      'player_code': playerCodeController.text.trim(),
      'photo_url': _emptyToNull(_photoUrl),
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'ci': _emptyToNull(ciController.text),
      'birth_date': _dateOnly(_birthDate!),
      'gender': _emptyToNull(_gender),
      'address': _emptyToNull(addressController.text),
      'school_name': _emptyToNull(schoolNameController.text),
      'registration_date': _dateOnly(_registrationDate),
      'status': _status,
    };
  }

  Map<String, dynamic> buildSportProfileMap() {
    return <String, dynamic>{
      'primary_position': _emptyToNull(primaryPositionController.text),
      'secondary_position': _emptyToNull(secondaryPositionController.text),
      'dominant_foot': _emptyToNull(_dominantFoot),
      'height_cm': _parseNullableDouble(heightController.text),
      'weight_kg': _parseNullableDouble(weightController.text),
      'shirt_size': _emptyToNull(shirtSizeController.text),
      'shorts_size': _emptyToNull(shortsSizeController.text),
      'socks_size': _emptyToNull(socksSizeController.text),
      'sport_notes': _emptyToNull(sportNotesController.text),
    };
  }

  Map<String, dynamic> buildMedicalProfileMap() {
    return <String, dynamic>{
      'blood_type': _emptyToNull(bloodTypeController.text),
      'allergies': _emptyToNull(allergiesController.text),
      'medications': _emptyToNull(medicationsController.text),
      'asthma': _hasAsthma,
      'previous_injuries': _emptyToNull(previousInjuriesController.text),
      'surgeries': _emptyToNull(surgeriesController.text),
      'medical_conditions': _emptyToNull(medicalConditionsController.text),
      'emergency_notes': _emptyToNull(emergencyNotesController.text),
      'medical_insurance': _emptyToNull(medicalInsuranceController.text),
    };
  }

  Map<String, dynamic> buildGuardianMap() {
    return <String, dynamic>{
      'first_name': guardianFirstNameController.text.trim(),
      'last_name': guardianLastNameController.text.trim(),
      'ci': _emptyToNull(guardianCiController.text),
      'phone': _emptyToNull(guardianPhoneController.text),
      'whatsapp': _emptyToNull(guardianWhatsAppController.text),
      'email': _emptyToNull(guardianEmailController.text),
      'address': _emptyToNull(guardianAddressController.text),
      'relationship': _emptyToNull(_guardianRelationship),
      'is_primary': _isPrimaryGuardian,
      'can_pick_up': _canPickUpPlayer,
    };
  }

  bool validateAllSteps() {
    final bool personalValid =
        personalFormKey.currentState?.validate() ?? false;

    final bool sportsValid = sportsFormKey.currentState?.validate() ?? false;

    final bool medicalValid = medicalFormKey.currentState?.validate() ?? false;

    final bool guardianValid =
        guardianFormKey.currentState?.validate() ?? false;

    return personalValid && sportsValid && medicalValid && guardianValid;
  }

  static String _numberToText(double? value) {
    if (value == null) {
      return '';
    }

    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  static String _normalizeGuardianRelationship(String value) {
    switch (value.trim().toLowerCase()) {
      case 'father':
        return 'father';
      case 'mother':
        return 'mother';
      case 'guardian':
      case 'legal_guardian':
        return 'guardian';
      case 'grandparent':
      case 'grandfather':
      case 'grandmother':
        return 'grandparent';
      default:
        return 'other';
    }
  }

  void _normalizeSelectedSportsOptions() {
    final String selectedTrainingGroupId = _trainingGroupId?.trim() ?? '';

    if (selectedTrainingGroupId.isNotEmpty && _trainingGroups.isNotEmpty) {
      Map<String, dynamic>? selectedGroup;

      for (final Map<String, dynamic> group in _trainingGroups) {
        final String groupId = group['id']?.toString().trim() ?? '';

        if (groupId == selectedTrainingGroupId) {
          selectedGroup = group;
          break;
        }
      }

      if (selectedGroup != null) {
        _categoryId = _normalizeNullableText(
          selectedGroup['category_id']?.toString(),
        );
      }
    }

    final String selectedCategoryId = _categoryId?.trim() ?? '';

    if (selectedCategoryId.isNotEmpty && _categories.isNotEmpty) {
      final bool categoryExists = _categories.any(
        (Map<String, dynamic> category) =>
            category['id']?.toString().trim() == selectedCategoryId,
      );

      if (!categoryExists) {
        _categoryId = null;
        _trainingGroupId = null;
      }
    }
  }

  static String? _normalizeNullableText(String? value) {
    final String text = value?.trim() ?? '';

    return text.isEmpty ? null : text;
  }

  static dynamic _emptyToNull(String? value) {
    return _normalizeNullableText(value);
  }

  static double? _parseNullableDouble(String value) {
    final String text = value.trim().replaceAll(',', '.');

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
  }

  static String _dateOnly(DateTime value) {
    final String year = value.year.toString().padLeft(4, '0');

    final String month = value.month.toString().padLeft(2, '0');

    final String day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<bool> savePlayer() async {
    clearError();
    setSaving(true);

    try {
      final String normalizedTrainingGroupId = trainingGroupId?.trim() ?? '';

      if (normalizedTrainingGroupId.isEmpty) {
        throw const FormatException(
          'Debes seleccionar un grupo de entrenamiento.',
        );
      }

      String playerId;

      if (isEditing) {
        final String existingPlayerId = _editingPlayerId?.trim() ?? '';

        if (existingPlayerId.isEmpty) {
          throw const FormatException(
            'No fue posible identificar al jugador que se desea editar.',
          );
        }

        await PlayerService.updatePlayer(
          playerId: existingPlayerId,
          player: buildPlayerMap(),
          sport: buildSportProfileMap(),
          medical: buildMedicalProfileMap(),
          guardian: buildGuardianMap(),
          trainingGroupId: normalizedTrainingGroupId,
        );

        playerId = existingPlayerId;
      } else {
        playerId = await _repository.registerPlayer(
          player: buildPlayerMap(),
          sport: buildSportProfileMap(),
          medical: buildMedicalProfileMap(),
          guardian: buildGuardianMap(),
          trainingGroupId: normalizedTrainingGroupId,
        );
      }

      final Uint8List? selectedPhotoBytes = _photoBytes;

      if (selectedPhotoBytes != null && selectedPhotoBytes.isNotEmpty) {
        final String photoUrl = await _storageService.uploadPlayerPhoto(
          bytes: selectedPhotoBytes,
          fileName: _photoFileName ?? 'player_photo.jpg',
          playerId: playerId,
        );

        await PlayerService.updatePlayerPhoto(
          playerId: playerId,
          photoUrl: photoUrl,
        );

        _photoUrl = photoUrl;
      }

      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setSaving(false);
    }
  }

  @override
  void dispose() {
    playerCodeController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    ciController.dispose();
    addressController.dispose();
    schoolNameController.dispose();

    primaryPositionController.dispose();
    secondaryPositionController.dispose();
    heightController.dispose();
    weightController.dispose();
    shirtSizeController.dispose();
    shortsSizeController.dispose();
    socksSizeController.dispose();
    sportNotesController.dispose();

    bloodTypeController.dispose();
    medicalInsuranceController.dispose();
    allergiesController.dispose();
    medicationsController.dispose();
    previousInjuriesController.dispose();
    surgeriesController.dispose();
    medicalConditionsController.dispose();
    emergencyNotesController.dispose();

    guardianFirstNameController.dispose();
    guardianLastNameController.dispose();
    guardianCiController.dispose();
    guardianPhoneController.dispose();
    guardianWhatsAppController.dispose();
    guardianEmailController.dispose();
    guardianAddressController.dispose();

    super.dispose();
  }
}
