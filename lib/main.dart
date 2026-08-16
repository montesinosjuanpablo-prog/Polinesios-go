import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/welcome/presentation/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );

    debugPrint('================================');
    debugPrint('SUPABASE CONECTADO CORRECTAMENTE');
    debugPrint('URL: ${SupabaseConfig.url}');
    debugPrint('================================');
  } else {
    debugPrint('================================');
    debugPrint('SUPABASE NO ESTÁ CONFIGURADO');
    debugPrint('Faltan SUPABASE_URL o SUPABASE_PUBLISHABLE_KEY');
    debugPrint('================================');
  }

  runApp(const PolinesiosGoApp());
}

class PolinesiosGoApp extends StatelessWidget {
  const PolinesiosGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polinesios GO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SupabaseConfig.isConfigured
          ? const WelcomeScreen()
          : const _SupabaseConfigurationScreen(),
    );
  }
}

class _SupabaseConfigurationScreen extends StatelessWidget {
  const _SupabaseConfigurationScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 80),
                      const SizedBox(height: 22),
                      const Text(
                        'Falta configurar Supabase',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Ejecuta Polinesios GO utilizando la URL y la '
                        'clave pública del proyecto de Supabase.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, height: 1.45),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const SelectableText(
                          'flutter run -d chrome '
                          '--dart-define=SUPABASE_URL=TU_URL '
                          '--dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
