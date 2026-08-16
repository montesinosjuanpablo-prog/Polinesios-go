import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../dashboard/presentation/admin_dashboard_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  String? _validatePassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return 'Ingresa tu contraseña';
    }

    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();

    final bool isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthResponse response = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user == null) {
        throw const AuthException('No se pudo iniciar la sesión.');
      }

      final Map<String, dynamic> profile =
          await AuthService.getCurrentProfile();

      final String role =
          profile['role']?.toString().trim().toLowerCase() ?? '';

      final String status =
          profile['status']?.toString().trim().toLowerCase() ?? '';

      final String firstName = profile['first_name']?.toString().trim() ?? '';

      if (status != 'active') {
        await AuthService.signOut();

        throw const AuthException(
          'Tu cuenta está inactiva. Comunícate con la escuela.',
        );
      }

      if (!mounted) {
        return;
      }

      switch (role) {
        case 'admin':
          setState(() {
            _isLoading = false;
          });

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => const AdminDashboardScreen(),
            ),
            (Route<dynamic> route) => false,
          );
          return;

        case 'coach':
          await AuthService.signOut();

          if (!mounted) {
            return;
          }

          _showMessage(
            firstName.isEmpty
                ? 'El panel del coach será construido próximamente.'
                : 'Hola, $firstName. El panel del coach será '
                      'construido próximamente.',
          );
          break;

        case 'guardian':
          await AuthService.signOut();

          if (!mounted) {
            return;
          }

          _showMessage(
            firstName.isEmpty
                ? 'El panel de padres y tutores será construido '
                      'próximamente.'
                : 'Hola, $firstName. El panel de padres y tutores '
                      'será construido próximamente.',
          );
          break;

        default:
          await AuthService.signOut();

          if (!mounted) {
            return;
          }

          _showMessage(
            'Tu cuenta no tiene un rol válido asignado.',
            isError: true,
          );
      }
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(_authErrorMessage(error.message), isError: true);
    } on PostgrestException catch (error) {
      await _safeSignOut();

      if (!mounted) {
        return;
      }

      _showMessage(_profileErrorMessage(error), isError: true);
    } catch (_) {
      await _safeSignOut();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Ocurrió un problema inesperado. '
        'Inténtalo nuevamente.',
        isError: true,
      );
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _safeSignOut() async {
    try {
      await AuthService.signOut();
    } catch (_) {
      // Evita que un error secundario al cerrar sesión
      // sustituya al mensaje original.
    }
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  String _authErrorMessage(String originalMessage) {
    final String message = originalMessage.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'El correo o la contraseña son incorrectos.';
    }

    if (message.contains('email not confirmed')) {
      return 'Debes confirmar tu correo antes de ingresar.';
    }

    if (message.contains('user not found')) {
      return 'No existe una cuenta registrada con ese correo.';
    }

    if (message.contains('too many requests') ||
        message.contains('rate limit')) {
      return 'Se realizaron demasiados intentos. '
          'Espera un momento y vuelve a intentarlo.';
    }

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('failed to fetch') ||
        message.contains('connection')) {
      return 'No se pudo conectar con el servidor. '
          'Revisa tu conexión a internet.';
    }

    if (message.contains('inactive')) {
      return originalMessage;
    }

    return 'No fue posible iniciar sesión. '
        'Verifica tus datos e inténtalo nuevamente.';
  }

  String _profileErrorMessage(PostgrestException error) {
    final String message = error.message.toLowerCase();

    if (message.contains('0 rows') ||
        message.contains('json object requested') ||
        message.contains('multiple')) {
      return 'Tu usuario existe, pero no tiene un perfil válido. '
          'Comunícate con la administración de Polinesios.';
    }

    if (message.contains('permission') ||
        message.contains('row-level security') ||
        message.contains('policy')) {
      return 'No fue posible acceder a tu perfil por una '
          'restricción de seguridad.';
    }

    return 'No fue posible consultar tu perfil de usuario.';
  }

  void _openPasswordRecovery() {
    FocusScope.of(context).unfocus();

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _showAccessInformation() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const _AccessInformationSheet();
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
          const _LoginBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxHeight < 760;

                final double horizontalPadding = constraints.maxWidth < 380
                    ? 16
                    : 24;

                final double topPadding = compact ? 4 : 10;

                final double bottomPadding = compact ? 16 : 30;

                return Column(
                  children: [
                    _TopBar(
                      compact: compact,
                      onBackPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          topPadding,
                          horizontalPadding,
                          bottomPadding,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Column(
                              children: [
                                _LoginHeader(compact: compact),
                                SizedBox(height: compact ? 16 : 28),
                                _LoginCard(
                                  compact: compact,
                                  formKey: _formKey,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  hidePassword: _hidePassword,
                                  rememberMe: _rememberMe,
                                  isLoading: _isLoading,
                                  emailValidator: _validateEmail,
                                  passwordValidator: _validatePassword,
                                  onPasswordVisibilityPressed: () {
                                    setState(() {
                                      _hidePassword = !_hidePassword;
                                    });
                                  },
                                  onRememberMeChanged: (bool value) {
                                    setState(() {
                                      _rememberMe = value;
                                    });
                                  },
                                  onLoginPressed: _submitLogin,
                                  onForgotPasswordPressed:
                                      _openPasswordRecovery,
                                ),
                                SizedBox(height: compact ? 12 : 22),
                                _AccessHelpButton(
                                  onPressed: _showAccessInformation,
                                ),
                                SizedBox(height: compact ? 12 : 24),
                                const Text(
                                  'Acceso exclusivo para la '
                                  'Familia Polinesios',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

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
          stops: [0.0, 0.35, 0.72, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.fuchsia.withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -100,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellow.withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBackPressed, required this.compact});

  final VoidCallback? onBackPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, compact ? 4 : 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed,
            tooltip: 'Volver',
            style: IconButton.styleFrom(
              foregroundColor: AppColors.white,
              disabledForegroundColor: Colors.white38,
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

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double logoSize = compact ? 92 : 130;

    final double titleSize = compact ? 24 : 29;

    final double subtitleSize = compact ? 14 : 16;

    return Column(
      children: [
        SizedBox(
          width: logoSize,
          height: logoSize,
          child: Image.asset(
            AppAssets.logo,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) {
                  return Icon(
                    Icons.shield_rounded,
                    color: AppColors.yellow,
                    size: logoSize * 0.76,
                  );
                },
          ),
        ),
        SizedBox(height: compact ? 8 : 14),
        Text(
          '¡Bienvenido de nuevo!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          'Ingresa a tu cuenta para continuar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: subtitleSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.compact,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.hidePassword,
    required this.rememberMe,
    required this.isLoading,
    required this.emailValidator,
    required this.passwordValidator,
    required this.onPasswordVisibilityPressed,
    required this.onRememberMeChanged,
    required this.onLoginPressed,
    required this.onForgotPasswordPressed,
  });

  final bool compact;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  final bool hidePassword;
  final bool rememberMe;
  final bool isLoading;

  final String? Function(String?) emailValidator;
  final String? Function(String?) passwordValidator;

  final VoidCallback onPasswordVisibilityPressed;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onLoginPressed;
  final VoidCallback onForgotPasswordPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        border: Border.all(color: AppColors.fuchsia.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: compact ? 20 : 30,
            offset: Offset(0, compact ? 10 : 18),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Iniciar sesión',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: compact ? 21 : 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: compact ? 16 : 22),
              TextFormField(
                controller: emailController,
                validator: emailValidator,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                autocorrect: false,
                decoration: _inputDecoration(
                  label: 'Correo electrónico',
                  hint: 'ejemplo@correo.com',
                  icon: Icons.email_outlined,
                ),
              ),
              SizedBox(height: compact ? 12 : 18),
              TextFormField(
                controller: passwordController,
                validator: passwordValidator,
                enabled: !isLoading,
                obscureText: hidePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                autocorrect: false,
                enableSuggestions: false,
                onFieldSubmitted: (_) {
                  if (!isLoading) {
                    onLoginPressed();
                  }
                },
                decoration: _inputDecoration(
                  label: 'Contraseña',
                  hint: 'Ingresa tu contraseña',
                  icon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    onPressed: isLoading ? null : onPasswordVisibilityPressed,
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
              SizedBox(height: compact ? 4 : 10),
              Row(
                children: [
                  Transform.scale(
                    scale: compact ? 0.92 : 1,
                    child: Checkbox(
                      value: rememberMe,
                      activeColor: AppColors.fuchsia,
                      onChanged: isLoading
                          ? null
                          : (bool? value) {
                              onRememberMeChanged(value ?? false);
                            },
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Recordarme',
                      style: TextStyle(
                        color: Color(0xFF444444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Flexible(
                    child: TextButton(
                      onPressed: isLoading ? null : onForgotPasswordPressed,
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: AppColors.fuchsia,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 16),
              SizedBox(
                height: compact ? 52 : 58,
                child: FilledButton(
                  onPressed: isLoading ? null : onLoginPressed,
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
                            key: ValueKey<String>('button'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login_rounded),
                              SizedBox(width: 10),
                              Text(
                                'INGRESAR',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
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
      disabledBorder: OutlineInputBorder(
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

class _AccessHelpButton extends StatelessWidget {
  const _AccessHelpButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.info_outline_rounded, color: AppColors.yellow),
      label: const Text(
        '¿Quién puede ingresar?',
        style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _AccessInformationSheet extends StatelessWidget {
  const _AccessInformationSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Acceso a Polinesios GO',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            const _AccessRole(
              icon: Icons.admin_panel_settings_rounded,
              title: 'Administrador',
              description:
                  'Gestiona jugadores, pagos, asistencia '
                  'y toda la escuela.',
            ),
            const _AccessRole(
              icon: Icons.sports_rounded,
              title: 'Coach',
              description:
                  'Consulta sus grupos, entrenamientos '
                  'y evaluaciones.',
            ),
            const _AccessRole(
              icon: Icons.family_restroom_rounded,
              title: 'Padre o tutor',
              description:
                  'Accede únicamente a la información '
                  'de sus hijos.',
            ),
            const SizedBox(height: 18),
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
      ),
    );
  }
}

class _AccessRole extends StatelessWidget {
  const _AccessRole({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.fuchsia.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.fuchsia),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF5C5257),
                    height: 1.35,
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
