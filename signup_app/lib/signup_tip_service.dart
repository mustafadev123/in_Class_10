import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

const signupTipRequest = <String, String>{
  'task': 'signup_tip',
  'topic': 'password_help',
};

abstract interface class SignupTipService {
  bool get isMock;

  Future<String> fetchTip();
}

class SignupTipException implements Exception {
  const SignupTipException(this.message);

  final String message;

  @override
  String toString() => message;
}

String normalizeSignupTip(String tip) {
  final trimmed = tip.trim();
  if (trimmed.isEmpty) {
    throw const SignupTipException('The service returned an empty tip.');
  }
  return trimmed.length <= 240 ? trimmed : trimmed.substring(0, 240);
}

class HttpSignupTipService implements SignupTipService {
  HttpSignupTipService({
    required this.endpoint,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final Uri endpoint;
  final http.Client _client;
  final Duration timeout;

  @override
  bool get isMock => false;

  @override
  Future<String> fetchTip() async {
    try {
      final response = await _client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(signupTipRequest),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw SignupTipException(
          'The tip service returned status ${response.statusCode}.',
        );
      }

      final Object? decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const SignupTipException('The service returned invalid JSON.');
      }

      if (decoded is! Map<String, dynamic>) {
        throw const SignupTipException(
          'The service response was not an object.',
        );
      }
      final tip = decoded['tip'];
      if (tip is! String) {
        throw const SignupTipException(
          'The service response did not contain a valid tip.',
        );
      }
      return normalizeSignupTip(tip);
    } on TimeoutException {
      throw const SignupTipException(
        'The request timed out. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const SignupTipException(
        'Could not reach the tip service. Check your connection and try again.',
      );
    }
  }
}

class MockSignupTipService implements SignupTipService {
  const MockSignupTipService({this.shouldFail = false});

  final bool shouldFail;

  @override
  bool get isMock => true;

  @override
  Future<String> fetchTip() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (shouldFail) {
      throw const SignupTipException(
        'Mock tip unavailable. Use Retry to try again.',
      );
    }
    return 'Use a unique passphrase with a mix of words, numbers, and symbols.';
  }
}
