import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:signup_app/signup_tip_service.dart';

void main() {
  final endpoint = Uri.parse('https://instructor.example/signup-tip');

  HttpSignupTipService serviceFor(
    Future<http.Response> Function(http.Request) handler, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    return HttpSignupTipService(
      endpoint: endpoint,
      client: MockClient(handler),
      timeout: timeout,
    );
  }

  test('sends the exact fixed JSON and returns a valid tip', () async {
    late http.Request capturedRequest;
    final service = serviceFor((request) async {
      capturedRequest = request;
      return http.Response('{"tip":"Use several random words."}', 200);
    });

    expect(await service.fetchTip(), 'Use several random words.');
    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url, endpoint);
    expect(capturedRequest.headers['content-type'], 'application/json');
    expect(jsonDecode(capturedRequest.body), signupTipRequest);
    expect((jsonDecode(capturedRequest.body) as Map).keys, hasLength(2));
  });

  test('rejects non-200 responses', () async {
    final service = serviceFor((_) async => http.Response('Unavailable', 503));

    await expectLater(
      service.fetchTip(),
      throwsA(
        isA<SignupTipException>().having(
          (error) => error.message,
          'message',
          contains('503'),
        ),
      ),
    );
  });

  test('rejects malformed JSON', () async {
    final service = serviceFor((_) async => http.Response('not json', 200));

    await expectLater(
      service.fetchTip(),
      throwsA(
        isA<SignupTipException>().having(
          (error) => error.message,
          'message',
          contains('invalid JSON'),
        ),
      ),
    );
  });

  for (final responseBody in ['{}', '{"tip":42}', '{"tip":"   "}']) {
    test('rejects missing, wrong-type, or empty tip: $responseBody', () async {
      final service = serviceFor((_) async => http.Response(responseBody, 200));

      await expectLater(service.fetchTip(), throwsA(isA<SignupTipException>()));
    });
  }

  test('reports a timeout', () async {
    final service = serviceFor((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return http.Response('{"tip":"Too late"}', 200);
    }, timeout: const Duration(milliseconds: 1));

    await expectLater(
      service.fetchTip(),
      throwsA(
        isA<SignupTipException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });

  test('reports an offline client error', () async {
    final service = serviceFor(
      (_) async => throw http.ClientException('offline'),
    );

    await expectLater(
      service.fetchTip(),
      throwsA(
        isA<SignupTipException>().having(
          (error) => error.message,
          'message',
          contains('Could not reach'),
        ),
      ),
    );
  });

  test('trims advice and limits it to 240 characters', () async {
    final longTip = '  ${'x' * 300}  ';
    final service = serviceFor(
      (_) async => http.Response(jsonEncode({'tip': longTip}), 200),
    );

    final result = await service.fetchTip();
    expect(result, hasLength(240));
    expect(result, isNot(startsWith(' ')));
    expect(result, isNot(endsWith(' ')));
  });

  test('mock behavior is deterministic for success and failure', () async {
    const success = MockSignupTipService();
    const failure = MockSignupTipService(shouldFail: true);

    expect(await success.fetchTip(), await success.fetchTip());
    await expectLater(failure.fetchTip(), throwsA(isA<SignupTipException>()));
  });
}
