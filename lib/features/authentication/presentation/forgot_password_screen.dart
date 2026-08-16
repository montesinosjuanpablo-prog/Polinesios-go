import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _sendRecoveryEmail() async {
    FocusScope.of(context).unfocus();

    final bool isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulación temporal.
    // Más adelante enviaremos el correo mediante Supabase.
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _emailSent = true;
    });
  }

  void _tryAnotherEmail() {
    setState(() {
      _emailSent = false;
      _emailController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _RecoveryBackground(),
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
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: _emailSent
                              ? _SuccessContent(
                                  key: const ValueKey<String>('success'),
                                  email: _emailController.text.trim(),
                                  onReturnToLogin: () {
                                    Navigator.of(context).pop();
                                  },
                                  onTryAnotherEmail: _tryAnotherEmail,
                                )
                              : _RecoveryContent(
                                  key: const ValueKey<String>('form'),
                                  formKey: _formKey,
                                  emailController: _emailController,
                                  emailValidator: _validateEmail,
                                  isLoading: _isLoading,
                                  onSendPressed: _sendRecoveryEmail,
                                ),
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

class _RecoveryBackground extends StatelessWidget {
  const _RecoveryBackground();

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
          stops: [0.0, 0.36, 0.73, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -75,
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
            bottom: 70,
            left: -110,
            child: Container(
              width: 290,
              height: 290,
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

class _RecoveryContent extends StatelessWidget {
  const _RecoveryContent({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.emailValidator,
    required this.isLoading,
    required this.onSendPressed,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final String? Function(String?) emailValidator;
  final bool isLoading;
  final VoidCallback onSendPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: Image.asset(
            AppAssets.logo,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.shield_rounded,
                color: AppColors.yellow,
                size: 100,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Recupera tu contraseña',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 29,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Te enviaremos las instrucciones para crear una nueva contraseña.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.45),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.fuchsia.withValues(alpha: 0.30),
            ),
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
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.fuchsia.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.fuchsia,
                    size: 37,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '¿Cuál es tu correo?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Utiliza el correo registrado en Polinesios GO.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64565D),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: emailController,
                  validator: emailValidator,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  onFieldSubmitted: (_) {
                    if (!isLoading) {
                      onSendPressed();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'ejemplo@correo.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF8F5F7),
                    prefixIconColor: AppColors.fuchsia,
                    labelStyle: const TextStyle(
                      color: Color(0xFF5A4550),
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
                      borderSide: const BorderSide(
                        color: AppColors.fuchsia,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 58,
                  child: FilledButton(
                    onPressed: isLoading ? null : onSendPressed,
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
                              key: ValueKey<String>('send'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded),
                                SizedBox(width: 10),
                                Text(
                                  'ENVIAR INSTRUCCIONES',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
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
        const SizedBox(height: 22),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security_rounded, color: AppColors.yellow, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Tu información está protegida.',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({
    super.key,
    required this.email,
    required this.onReturnToLogin,
    required this.onTryAnotherEmail,
  });

  final String email;
  final VoidCallback onReturnToLogin;
  final VoidCallback onTryAnotherEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: Image.asset(
            AppAssets.logo,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.shield_rounded,
                color: AppColors.yellow,
                size: 100,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.fuchsia.withValues(alpha: 0.13),
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.fuchsia,
                  size: 52,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                '¡Revisa tu correo!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enviamos las instrucciones para recuperar tu contraseña a:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64565D),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fuchsia.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.fuchsia,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'El enlace será válido durante un tiempo limitado. Revisa también la carpeta de correo no deseado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64565D),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: onReturnToLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'VOLVER AL LOGIN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onTryAnotherEmail,
                child: const Text(
                  'Usar otro correo electrónico',
                  style: TextStyle(
                    color: AppColors.fuchsia,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
