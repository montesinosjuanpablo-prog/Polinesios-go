import 'package:flutter_test/flutter_test.dart';
import 'package:polinesios_go/main.dart';

void main() {
  testWidgets('Polinesios GO inicia correctamente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PolinesiosGoApp());

    expect(find.text('POLINESIOS'), findsOneWidget);
    expect(find.text('GO'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
  });
}
