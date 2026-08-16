import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _invitationController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  String _selectedRole = 'Padre o tutor';

  final List<String> _roles = <String>['Padre o tutor', 'Coach'];

  @override
  void dispose() {
    _invitationController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa $fieldName';
    }

    return null;
  }

  String? _validateInvitationCode(String? value) {
    final String code = value?.trim().toUpperCase() ?? '';

    if (code.isEmpty) {
      return 'Ingresa el código de invitación';
    }

    if (code.length < 6) {
      return 'El código debe tener al menos 6 caracteres';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Ingresa tu correo electrónico';
    }

    final RegExp emailPattern = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!emailPattern.hasMatch(email)) {
      return 'Ingresa un correo electrónico válido';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final String phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Ingresa tu número de teléfono';
    }

    final String digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length < 7) {
      return 'Ingresa un número de teléfono válido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return 'Ingresa una contraseña';
    }

    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Incluye al menos una letra mayúscula';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Incluye al menos un número';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();

    final bool isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text(
            'Debes aceptar los términos y la política de privacidad.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Registro provisional.
    // Más adelante se conectará con Supabase.
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.fuchsia,
            size: 58,
          ),
          title: const Text(
            '¡Registro preparado!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'La cuenta de ${_nameController.text.trim()} '
            '${_lastNameController.text.trim()} está lista '
            'para conectarse con el sistema de Polinesios GO.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('IR AL LOGIN'),
            ),
          ],
        );
      },
    );
  }

  void _showTerms() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const _TermsSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _RegisterBackground(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  onBackPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          children: [
                            const _RegisterHeader(),
                            const SizedBox(height: 24),
                            _RegisterCard(
                              formKey: _formKey,
                              invitationController: _invitationController,
                              nameController: _nameController,
                              lastNameController: _lastNameController,
                              emailController: _emailController,
                              phoneController: _phoneController,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              roles: _roles,
                              selectedRole: _selectedRole,
                              hidePassword: _hidePassword,
                              hideConfirmPassword: _hideConfirmPassword,
                              acceptTerms: _acceptTerms,
                              isLoading: _isLoading,
                              invitationValidator: _validateInvitationCode,
                              requiredValidator: _requiredValidator,
                              emailValidator: _validateEmail,
                              phoneValidator: _validatePhone,
                              passwordValidator: _validatePassword,
                              confirmPasswordValidator:
                                  _validateConfirmPassword,
                              onRoleChanged: (String? value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _selectedRole = value;
                                });
                              },
                              onPasswordVisibilityPressed: () {
                                setState(() {
                                  _hidePassword = !_hidePassword;
                                });
                              },
                              onConfirmPasswordVisibilityPressed: () {
                                setState(() {
                                  _hideConfirmPassword = !_hideConfirmPassword;
                                });
                              },
                              onAcceptTermsChanged: (bool value) {
                                setState(() {
                                  _acceptTerms = value;
                                });
                              },
                              onTermsPressed: _showTerms,
                              onRegisterPressed: _submitRegistration,
                            ),
                            const SizedBox(height: 20),
                            const _InvitationInformation(),
                          ],
                        ),
                      ),
                    ),
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

class _RegisterBackground extends StatelessWidget {
  const _RegisterBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF3A001F),
            AppColors.darkFuchsia,
            Color(0xFF210013),
            AppColors.black,
          ],
          stops: [0.0, 0.34, 0.72, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.fuchsia.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            right: -90,
            bottom: 140,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellow.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed,
            tooltip: 'Volver',
            style: IconButton.styleFrom(
              foregroundColor: AppColors.white,
              backgroundColor: Colors.black.withValues(alpha: 0.22),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Spacer(),
          const Text(
            'POLINESIOS GO',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Image.asset(
            AppAssets.logo,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.shield_rounded,
                color: AppColors.yellow,
                size: 95,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Crea tu cuenta',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 29,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Únete a la comunidad de Polinesios',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.formKey,
    required this.invitationController,
    required this.nameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.roles,
    required this.selectedRole,
    required this.hidePassword,
    required this.hideConfirmPassword,
    required this.acceptTerms,
    required this.isLoading,
    required this.invitationValidator,
    required this.requiredValidator,
    required this.emailValidator,
    required this.phoneValidator,
    required this.passwordValidator,
    required this.confirmPasswordValidator,
    required this.onRoleChanged,
    required this.onPasswordVisibilityPressed,
    required this.onConfirmPasswordVisibilityPressed,
    required this.onAcceptTermsChanged,
    required this.onTermsPressed,
    required this.onRegisterPressed,
  });

  final GlobalKey<FormState> formKey;

  final TextEditingController invitationController;
  final TextEditingController nameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final List<String> roles;
  final String selectedRole;

  final bool hidePassword;
  final bool hideConfirmPassword;
  final bool acceptTerms;
  final bool isLoading;

  final String? Function(String?) invitationValidator;
  final String? Function(String?, String) requiredValidator;
  final String? Function(String?) emailValidator;
  final String? Function(String?) phoneValidator;
  final String? Function(String?) passwordValidator;
  final String? Function(String?) confirmPasswordValidator;

  final ValueChanged<String?> onRoleChanged;
  final VoidCallback onPasswordVisibilityPressed;
  final VoidCallback onConfirmPasswordVisibilityPressed;
  final ValueChanged<bool> onAcceptTermsChanged;
  final VoidCallback onTermsPressed;
  final VoidCallback onRegisterPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Registro por invitación',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.black,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Utiliza el código proporcionado por la escuela.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64565D), height: 1.4),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: invitationController,
              validator: invitationValidator,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                label: 'Código de invitación',
                hint: 'Ejemplo: POLI-2026',
                icon: Icons.vpn_key_outlined,
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              items: roles.map((String role) {
                return DropdownMenuItem<String>(value: role, child: Text(role));
              }).toList(),
              onChanged: isLoading ? null : onRoleChanged,
              decoration: _inputDecoration(
                label: 'Tipo de usuario',
                hint: 'Selecciona tu perfil',
                icon: Icons.badge_outlined,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: nameController,
              validator: (String? value) {
                return requiredValidator(value, 'tu nombre');
              },
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                label: 'Nombre',
                hint: 'Ingresa tu nombre',
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: lastNameController,
              validator: (String? value) {
                return requiredValidator(value, 'tus apellidos');
              },
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                label: 'Apellidos',
                hint: 'Ingresa tus apellidos',
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: emailController,
              validator: emailValidator,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              decoration: _inputDecoration(
                label: 'Correo electrónico',
                hint: 'ejemplo@correo.com',
                icon: Icons.email_outlined,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: phoneController,
              validator: phoneValidator,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: _inputDecoration(
                label: 'Teléfono o WhatsApp',
                hint: 'Ingresa tu número',
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: passwordController,
              validator: passwordValidator,
              obscureText: hidePassword,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.newPassword],
              decoration: _inputDecoration(
                label: 'Contraseña',
                hint: 'Crea una contraseña segura',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  onPressed: onPasswordVisibilityPressed,
                  tooltip: hidePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: confirmPasswordController,
              validator: confirmPasswordValidator,
              obscureText: hideConfirmPassword,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              onFieldSubmitted: (_) {
                if (!isLoading) {
                  onRegisterPressed();
                }
              },
              decoration: _inputDecoration(
                label: 'Confirmar contraseña',
                hint: 'Repite tu contraseña',
                icon: Icons.lock_reset_rounded,
                suffixIcon: IconButton(
                  onPressed: onConfirmPasswordVisibilityPressed,
                  tooltip: hideConfirmPassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  icon: Icon(
                    hideConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: acceptTerms,
                  activeColor: AppColors.fuchsia,
                  onChanged: isLoading
                      ? null
                      : (bool? value) {
                          onAcceptTermsChanged(value ?? false);
                        },
                ),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Acepto los ',
                        style: TextStyle(
                          color: Color(0xFF51484C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      InkWell(
                        onTap: isLoading ? null : onTermsPressed,
                        child: const Text(
                          'términos y la política de privacidad',
                          style: TextStyle(
                            color: AppColors.fuchsia,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 58,
              child: FilledButton(
                onPressed: isLoading ? null : onRegisterPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.black,
                  disabledBackgroundColor: AppColors.yellow.withValues(
                    alpha: 0.55,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? const SizedBox(
                          key: ValueKey<String>('loading'),
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.black,
                          ),
                        )
                      : const Row(
                          key: ValueKey<String>('register'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_alt_1_rounded),
                            SizedBox(width: 10),
                            Text(
                              'CREAR CUENTA',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8F5F7),
      labelStyle: const TextStyle(
        color: Color(0xFF5A4550),
        fontWeight: FontWeight.w700,
      ),
      prefixIconColor: AppColors.fuchsia,
      suffixIconColor: AppColors.fuchsia,
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
}

class _InvitationInformation extends StatelessWidget {
  const _InvitationInformation();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.fuchsia.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.security_rounded, color: AppColors.yellow, size: 27),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'El registro requiere una invitación para proteger '
              'la información de los jugadores y sus familias.',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSheet extends StatelessWidget {
  const _TermsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Términos y privacidad',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    _TermsSection(
                      title: 'Uso de la plataforma',
                      text:
                          'Polinesios GO es una herramienta privada '
                          'para la gestión y comunicación de la '
                          'Escuela Formativa Polinesios.',
                    ),
                    _TermsSection(
                      title: 'Información de los jugadores',
                      text:
                          'Cada padre o tutor podrá consultar '
                          'únicamente la información de los jugadores '
                          'que estén vinculados a su cuenta.',
                    ),
                    _TermsSection(
                      title: 'Protección de datos',
                      text:
                          'La información personal, médica, deportiva '
                          'y administrativa deberá utilizarse '
                          'exclusivamente para las actividades de la '
                          'escuela.',
                    ),
                    _TermsSection(
                      title: 'Credenciales',
                      text:
                          'Cada usuario es responsable de proteger su '
                          'correo electrónico, contraseña y código de '
                          'invitación.',
                    ),
                    _TermsSection(
                      title: 'Fotografías y comunicaciones',
                      text:
                          'El uso de fotografías, videos y mensajes '
                          'se realizará según las autorizaciones '
                          'registradas por cada padre o tutor.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('ENTENDIDO'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.fuchsia,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF51484C),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
