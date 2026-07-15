import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/presentation/providers/auth_provider.dart';
import 'package:genesis_airsoft_stock/presentation/screens/login_screen.dart';

import '../../helpers/mock_repositories.dart';

Widget buildScreen({MockAuthService? auth}) {
  final service = auth ?? MockAuthService();
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(service),
    ],
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  group('LoginScreen — renderizado', () {
    testWidgets('muestra título "Genesis"', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.textContaining('Genesis'), findsOneWidget);
    });

    testWidgets('muestra subtítulo "Stock & Finanzas"', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Stock & Finanzas'), findsOneWidget);
    });

    testWidgets('muestra campo de correo electrónico', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.widgetWithText(TextField, 'Correo electrónico'), findsOneWidget);
    });

    testWidgets('muestra campo de contraseña', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.widgetWithText(TextField, 'Contraseña'), findsOneWidget);
    });

    testWidgets('muestra botón "Ingresar"', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Ingresar'), findsOneWidget);
    });

    testWidgets('contraseña está oculta por defecto', (tester) async {
      await tester.pumpWidget(buildScreen());
      final field = tester.widget<TextField>(find.widgetWithText(TextField, 'Contraseña'));
      expect(field.obscureText, isTrue);
    });

    testWidgets('muestra ícono visibility_outlined inicialmente', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });

  group('LoginScreen — validación', () {
    testWidgets('campos vacíos → muestra error', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.tap(find.text('Ingresar'));
      await tester.pump();

      expect(find.text('El correo y la contraseña son requeridos'), findsOneWidget);
    });

    testWidgets('solo email → muestra error por contraseña vacía', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.enterText(find.byType(TextField).first, 'test@test.com');
      await tester.tap(find.text('Ingresar'));
      await tester.pump();

      expect(find.text('El correo y la contraseña son requeridos'), findsOneWidget);
    });

    testWidgets('solo password → muestra error por email vacío', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.enterText(find.byType(TextField).last, 'secret123');
      await tester.tap(find.text('Ingresar'));
      await tester.pump();

      expect(find.text('El correo y la contraseña son requeridos'), findsOneWidget);
    });

    testWidgets('campos vacíos → NO llama signIn', (tester) async {
      final auth = MockAuthService();
      await tester.pumpWidget(buildScreen(auth: auth));
      await tester.tap(find.text('Ingresar'));
      await tester.pump();

      expect(auth.signInCallCount, 0);
    });
  });

  group('LoginScreen — toggle contraseña', () {
    testWidgets('tap ojo → contraseña visible', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField).last);
      expect(field.obscureText, isFalse);
    });

    testWidgets('tap ojo → ícono cambia a visibility_off_outlined', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('doble tap ojo → vuelve a ocultar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField).last);
      expect(field.obscureText, isTrue);
    });
  });

  group('LoginScreen — flujo exitoso', () {
    testWidgets('credenciales válidas → llama signIn una vez', (tester) async {
      final auth = MockAuthService();
      await tester.pumpWidget(buildScreen(auth: auth));

      await tester.enterText(find.byType(TextField).first, 'admin@test.com');
      await tester.enterText(find.byType(TextField).last, 'pass1234');
      await tester.tap(find.text('Ingresar'));
      await tester.pump();

      expect(auth.signInCallCount, 1);
    });
  });

  group('LoginScreen — errores Firebase', () {
    Future<void> tapWithCreds(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).first, 'a@b.com');
      await tester.enterText(find.byType(TextField).last, 'pass');
      await tester.tap(find.text('Ingresar'));
      await tester.pump();
    }

    testWidgets('wrong-password → "Correo o contraseña incorrectos"', (tester) async {
      final auth = MockAuthService()
        ..throwOnSignIn = FirebaseAuthException(code: 'wrong-password');
      await tester.pumpWidget(buildScreen(auth: auth));
      await tapWithCreds(tester);

      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    });

    testWidgets('invalid-credential → "Correo o contraseña incorrectos"', (tester) async {
      final auth = MockAuthService()
        ..throwOnSignIn = FirebaseAuthException(code: 'invalid-credential');
      await tester.pumpWidget(buildScreen(auth: auth));
      await tapWithCreds(tester);

      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    });

    testWidgets('user-not-found → "No existe una cuenta con ese correo"', (tester) async {
      final auth = MockAuthService()
        ..throwOnSignIn = FirebaseAuthException(code: 'user-not-found');
      await tester.pumpWidget(buildScreen(auth: auth));
      await tapWithCreds(tester);

      expect(find.text('No existe una cuenta con ese correo'), findsOneWidget);
    });

    testWidgets('invalid-email → "Correo inválido"', (tester) async {
      final auth = MockAuthService()
        ..throwOnSignIn = FirebaseAuthException(code: 'invalid-email');
      await tester.pumpWidget(buildScreen(auth: auth));
      await tapWithCreds(tester);

      expect(find.text('Correo inválido'), findsOneWidget);
    });

    testWidgets('too-many-requests → "Demasiados intentos. Intente más tarde"', (tester) async {
      final auth = MockAuthService()
        ..throwOnSignIn = FirebaseAuthException(code: 'too-many-requests');
      await tester.pumpWidget(buildScreen(auth: auth));
      await tapWithCreds(tester);

      expect(find.text('Demasiados intentos. Intente más tarde'), findsOneWidget);
    });

    testWidgets('código desconocido → mensaje genérico', (tester) async {
      final auth = MockAuthService()
        ..throwOnSignIn = FirebaseAuthException(code: 'network-error', message: 'sin red');
      await tester.pumpWidget(buildScreen(auth: auth));
      await tapWithCreds(tester);

      expect(find.textContaining('Error al iniciar sesión'), findsOneWidget);
    });
  });
}
