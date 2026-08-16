import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../authentication/presentation/login_screen.dart';
import '../../authentication/presentation/register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const double _maxContentWidth = 520;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _StadiumBackground(),
          const _BackgroundOverlay(),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double availableWidth = constraints.maxWidth - 28;
                final double designWidth = availableWidth < _maxContentWidth
                    ? availableWidth
                    : _maxContentWidth;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: designWidth,
                        height: 860,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _PolinesiosLogo(),
                            const SizedBox(height: 8),
                            const _PolinesiosTitle(),
                            const SizedBox(height: 2),
                            const _GoLogo(),
                            const SizedBox(height: 10),
                            const _InstitutionalPhrase(),
                            const SizedBox(height: 4),
                            _PlayersAndLoginSection(
                              onLoginPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            _RegisterButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            const _VersionText(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StadiumBackground extends StatelessWidget {
  const _StadiumBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.30,
          0.30,
          0.30,
          0,
          0,
          0.30,
          0.30,
          0.30,
          0,
          0,
          0.30,
          0.30,
          0.30,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: Image.asset(
          AppAssets.stadiumBackground,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return const ColoredBox(color: AppColors.darkFuchsia);
          },
        ),
      ),
    );
  }
}

class _BackgroundOverlay extends StatelessWidget {
  const _BackgroundOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: AppColors.fuchsia.withValues(alpha: 0.46)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2B0019).withValues(alpha: 0.28),
                  AppColors.darkFuchsia.withValues(alpha: 0.48),
                  AppColors.fuchsia.withValues(alpha: 0.34),
                  AppColors.black.withValues(alpha: 0.78),
                  AppColors.black.withValues(alpha: 0.96),
                ],
                stops: const [0.0, 0.30, 0.56, 0.82, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolinesiosLogo extends StatefulWidget {
  const _PolinesiosLogo();

  @override
  State<_PolinesiosLogo> createState() {
    return _PolinesiosLogoState();
  }
}

class _PolinesiosLogoState extends State<_PolinesiosLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.09,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _playInitialHeartbeat();
  }

  Future<void> _playInitialHeartbeat() async {
    for (int index = 0; index < 2; index++) {
      if (!mounted) {
        return;
      }

      await _controller.forward();
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: 180,
        height: 180,
        child: Image.asset(
          AppAssets.logo,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.shield_rounded,
              size: 130,
              color: AppColors.yellow,
            );
          },
        ),
      ),
    );
  }
}

class _PolinesiosTitle extends StatelessWidget {
  const _PolinesiosTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'POLINESIOS',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.white,
        fontSize: 40,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        letterSpacing: 1.2,
        height: 1,
        shadows: [
          Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
    );
  }
}

class _GoLogo extends StatelessWidget {
  const _GoLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 105,
      child: Image.asset(
        AppAssets.goLogo,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return const Text(
            'GO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.yellow,
              fontSize: 70,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          );
        },
      ),
    );
  }
}

class _InstitutionalPhrase extends StatelessWidget {
  const _InstitutionalPhrase();

  @override
  Widget build(BuildContext context) {
    const TextStyle whiteStyle = TextStyle(
      color: AppColors.white,
      fontSize: 19,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      height: 1.42,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 3)),
      ],
    );

    const TextStyle yellowInitialStyle = TextStyle(
      color: AppColors.yellow,
      fontSize: 19,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      height: 1.42,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 3)),
      ],
    );

    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'R', style: yellowInitialStyle),
          TextSpan(text: 'espeto, ', style: whiteStyle),
          TextSpan(text: 'D', style: yellowInitialStyle),
          TextSpan(text: 'isciplina y ', style: whiteStyle),
          TextSpan(text: 'P', style: yellowInitialStyle),
          TextSpan(text: 'asión,\n', style: whiteStyle),
          TextSpan(text: 'esa es nuestra ', style: whiteStyle),
          TextSpan(text: 'F', style: yellowInitialStyle),
          TextSpan(text: 'ormación', style: whiteStyle),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _PlayersAndLoginSection extends StatelessWidget {
  const _PlayersAndLoginSection({required this.onLoginPressed});

  final VoidCallback onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 330,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 292,
            child: Image.asset(
              AppAssets.welcomePlayers,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.groups_rounded,
                    color: AppColors.fuchsia,
                    size: 110,
                  ),
                );
              },
            ),
          ),

          // El botón queda por delante de la parte inferior
          // de la imagen, eliminando el espacio visual.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _LoginButton(onPressed: onLoginPressed),
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.person_rounded, size: 25),
        label: const Text(
          'Iniciar sesión',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: AppColors.black,
          elevation: 8,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.fuchsia,
          backgroundColor: AppColors.black.withValues(alpha: 0.40),
          side: const BorderSide(color: AppColors.fuchsia, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          'Registrarse',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _VersionText extends StatelessWidget {
  const _VersionText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Versión 1.0.0',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.fuchsia,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
