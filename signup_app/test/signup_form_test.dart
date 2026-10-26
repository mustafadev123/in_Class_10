import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:signup_app/main.dart';
import 'package:signup_app/signup_tip_service.dart';

void main() {
  Future<void> pumpSignup(
    WidgetTester tester, {
    SignupTipService? service,
  }) async {
    await tester.pumpWidget(MaterialApp(home: SignupPage(tipService: service)));
  }

  Future<void> enterForm(
    WidgetTester tester, {
    String name = 'Taylor Student',
    String email = 'taylor@example.com',
    String password = 'secret7',
    String confirmation = 'secret7',
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.at(1), email);
    await tester.enterText(fields.at(2), password);
    await tester.enterText(fields.at(3), confirmation);
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.text(label);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  group('local signup validation', () {
    testWidgets('rejects empty and whitespace-only names', (tester) async {
      await pumpSignup(tester);
      await enterForm(tester, name: '   ');
      await tapButton(tester, 'Sign Up');

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('rejects empty and invalid email addresses', (tester) async {
      await pumpSignup(tester);
      await enterForm(tester, email: '');
      await tapButton(tester, 'Sign Up');
      expect(find.text('Please enter your email'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(1), 'not-an-email');
      await tapButton(tester, 'Sign Up');
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('rejects empty and short passwords', (tester) async {
      await pumpSignup(tester);
      await enterForm(tester, password: '', confirmation: '');
      await tapButton(tester, 'Sign Up');
      expect(find.text('Please enter a password'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(2), '12345');
      await tester.enterText(find.byType(TextFormField).at(3), '12345');
      await tapButton(tester, 'Sign Up');
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('rejects a mismatch after the original password changes', (
      tester,
    ) async {
      await pumpSignup(tester);
      await enterForm(tester);
      await tester.enterText(find.byType(TextFormField).at(2), 'changed8');
      await tapButton(tester, 'Sign Up');

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('valid input shows personalized success', (tester) async {
      await pumpSignup(tester);
      await enterForm(tester, name: '  Taylor Student  ');
      await tapButton(tester, 'Sign Up');

      expect(
        find.text(
          'Welcome, Taylor Student! Your demo signup passed validation.',
        ),
        findsOneWidget,
      );
    });
  });

  group('signup coach UI', () {
    testWidgets('shows loading and prevents duplicate requests', (
      tester,
    ) async {
      final service = _CompleterTipService();
      await pumpSignup(tester, service: service);

      await tapButton(tester, 'Get a signup tip.');
      expect(find.text('Getting a tip...'), findsOneWidget);
      expect(service.callCount, 1);

      await tester.tap(find.text('Getting a tip...'));
      await tester.pump();
      expect(service.callCount, 1);

      service.completer.complete('A useful tip');
      await tester.pumpAndSettle();
      expect(find.text('A useful tip'), findsOneWidget);
    });

    testWidgets('labels a successful live-service response as AI-generated', (
      tester,
    ) async {
      await pumpSignup(tester, service: const _TipService('Use a passphrase.'));
      await tapButton(tester, 'Get a signup tip.');
      await tester.pumpAndSettle();

      expect(find.text('AI-generated advice'), findsOneWidget);
      expect(find.text('Use a passphrase.'), findsOneWidget);
    });

    testWidgets('shows a friendly error and retries successfully', (
      tester,
    ) async {
      final service = _FailThenSucceedTipService();
      await pumpSignup(tester, service: service);
      await tapButton(tester, 'Get a signup tip.');
      await tester.pumpAndSettle();

      expect(find.text('Temporary test failure.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tapButton(tester, 'Retry');
      await tester.pumpAndSettle();
      expect(find.text('Retry worked.'), findsOneWidget);
      expect(service.callCount, 2);
    });

    testWidgets('AI failure does not block an otherwise valid signup', (
      tester,
    ) async {
      await pumpSignup(tester, service: const _FailingTipService());
      await enterForm(tester);
      await tapButton(tester, 'Get a signup tip.');
      await tester.pumpAndSettle();
      expect(find.text('Test service unavailable.'), findsOneWidget);

      await tapButton(tester, 'Sign Up');
      expect(
        find.text(
          'Welcome, Taylor Student! Your demo signup passed validation.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('AI success cannot bypass invalid form fields', (tester) async {
      await pumpSignup(tester, service: const _TipService('Use a passphrase.'));
      await tapButton(tester, 'Get a signup tip.');
      await tester.pumpAndSettle();
      await tapButton(tester, 'Sign Up');

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('form values never enter the AI request body', (tester) async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response('{"tip":"Safe tip"}', 200);
      });
      final service = HttpSignupTipService(
        endpoint: Uri.parse('https://instructor.example/signup-tip'),
        client: client,
      );
      await pumpSignup(tester, service: service);
      await enterForm(
        tester,
        name: 'Synthetic Private Name',
        email: 'private@example.com',
        password: 'PrivatePassword7!',
        confirmation: 'PrivatePassword7!',
      );

      await tapButton(tester, 'Get a signup tip.');
      await tester.pumpAndSettle();

      expect(
        capturedRequest.body,
        '{"task":"signup_tip","topic":"password_help"}',
      );
      expect(capturedRequest.body, isNot(contains('Synthetic Private Name')));
      expect(capturedRequest.body, isNot(contains('private@example.com')));
      expect(capturedRequest.body, isNot(contains('PrivatePassword7!')));
    });
  });
}

class _TipService implements SignupTipService {
  const _TipService(this.tip);

  final String tip;

  @override
  bool get isMock => false;

  @override
  Future<String> fetchTip() async => tip;
}

class _FailingTipService implements SignupTipService {
  const _FailingTipService();

  @override
  bool get isMock => false;

  @override
  Future<String> fetchTip() async {
    throw const SignupTipException('Test service unavailable.');
  }
}

class _CompleterTipService implements SignupTipService {
  final completer = Completer<String>();
  int callCount = 0;

  @override
  bool get isMock => false;

  @override
  Future<String> fetchTip() {
    callCount++;
    return completer.future;
  }
}

class _FailThenSucceedTipService implements SignupTipService {
  int callCount = 0;

  @override
  bool get isMock => false;

  @override
  Future<String> fetchTip() async {
    callCount++;
    if (callCount == 1) {
      throw const SignupTipException('Temporary test failure.');
    }
    return 'Retry worked.';
  }
}
