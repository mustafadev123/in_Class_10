# Flutter Activity 10: Signup Form Quest

**Submission:** Individual

**Track:** Graduate

**Selected tasks:** Task A — AI Signup Coach; Task C — Confirm & Celebrate

**Student name:** `Muhammad Mustufa`

This is a demonstration signup form. It validates input locally but does not
create, transmit, or store an account.

## Setup and commands

Requirements: Flutter 3.47.4 or a compatible stable release, an Android SDK,
and Java 17.

```sh
flutter pub get
flutter run
flutter test
flutter analyze
flutter build apk --release
```

The generated release APK is:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## How the starter was extended

The instructor's recognizable `MyApp -> MaterialApp -> SignupPage` structure
was retained. `SignupPage` remains a `StatefulWidget` containing a `Form`, a
`GlobalKey<FormState>`, `TextEditingController`s, inline validators, outlined
fields, and field icons.

The starter was extended with:

- A confirm-password field that must exactly match the current password.
- A personalized green success `SnackBar` shown only after all fields validate.
- Controller disposal and a scrollable, keyboard-safe layout.
- A cohesive purple Material 3 theme with lightly filled form fields.
- A signup-tip UI with loading, disabled duplicate requests, friendly errors,
  retry, plain-text output, and safe asynchronous widget-lifecycle checks.
- A small replaceable service interface with HTTP and deterministic mock
  implementations.

## AI signup coach and privacy boundary

The instructor did not provide an endpoint URL or access instructions.
Therefore, the running app uses `MockSignupTipService`, displays
**"Mock advice (no live AI called)"**, and never claims that its local response
came from AI. No live model is called. The mock has repeatable success and
failure modes for testing.

`HttpSignupTipService` is included for use only if the instructor later
provides an HTTPS endpoint. Configure it by constructing the service with the
instructor's `Uri` and injecting it into `SignupPage`. Do not add a provider key
to the app or repository.

The HTTP implementation sends exactly:

```json
{"task":"signup_tip","topic":"password_help"}
```

Names, email addresses, passwords, confirmation values, and other form data are
never passed to the tip service. The client expects HTTP 200 with a nonempty
string in `{"tip":"..."}`. It handles non-200 responses, invalid JSON,
missing/wrong-type/empty tips, connection failures, and a 10-second timeout.
Displayed advice is trimmed, limited to 240 characters, and rendered as plain
text. Local signup validation never depends on the tip service or its output.

## Tests and verified results

Verified on October 26, 2026:

- `dart format lib test`: passed; four files checked and no changes required.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed all 21 tests.
- `flutter build apk --release`: passed; generated a 45.7 MB APK.
- `flutter devices`: detected a physical Samsung SM S731U1 running Android 17,
  plus Windows, Chrome, and Edge targets.
- `flutter run -d R5CYA0BD7ET --debug --no-resident`: built, installed, and
  launched successfully on the physical Android device without a startup error.

Automated coverage includes form validation, confirmation after changing the
original password, personalized success, loading and duplicate prevention,
valid and invalid service responses, timeout/offline behavior, retry, trimming,
the 240-character limit, deterministic mock behavior, and independence between
AI advice and local validation. A privacy test fills every form field with
synthetic values and confirms the outbound body contains only the two fixed
request fields.

The device smoke check confirms installation and startup. There is
confirmed completion of the manual UI check after reviewing the form, keyboard
scrolling, mock-tip button, retry presentation, and success `SnackBar`.

## Known limitations

- No instructor endpoint was supplied, so the app uses labeled mock advice.
- The app intentionally does not create accounts, authenticate users, store
  credentials, or send form values anywhere.
- The generated Android project currently signs release builds with Flutter's
  debug signing configuration, which is suitable for this classroom APK but not
  for production distribution.

## Assistance and individual contribution

I did most of the code myself since starter code was already given and we ust had to make ammendments to that.I only took assistance in choosing the theme like i looked on internet for themes. 



## Graduate rubric checklist

- [x] Instructor starter structure preserved.
- [x] Name, email, and password fields use local inline validation.
- [x] Whitespace-only names and emails are rejected.
- [x] Confirm-password mismatch blocks submission.
- [x] Valid submission shows a personalized green success message.
- [x] Layout scrolls safely when the keyboard is present.
- [x] Controllers are disposed.
- [x] One coherent visual theme customization is present.
- [x] Signup-tip button provides loading, result, error, and retry states.
- [x] Duplicate tip requests are disabled while loading.
- [x] Tip service is replaceable and has deterministic mock behavior.
- [x] Mock output is clearly labeled; no live model is represented.
- [x] HTTP implementation uses the exact fixed, privacy-limited request body.
- [x] Timeout, network, status, JSON, schema, and empty-output errors are handled.
- [x] Advice is plain text, trimmed, and limited to 240 characters.
- [x] AI availability and output cannot approve, reject, or block local signup.
- [x] Automated validation, service, retry, and privacy tests pass.
- [x] Release APK builds successfully.
- [x] Add student name and personal contribution statement.
- [x] Complete the three personal reflections below.
- [x] Perform and record the final manual UI inspection.
- [ ] Submit the repository link and APK.

## Graduate reflections

### 1. Privacy or security boundary

**Question:** Identify one privacy or security boundary in the
client-to-proxy-to-model flow. What threat does it reduce, and what risk
remains?

In my app, the signup coach only uses the fixed task and topic values. It does
not receive the user's name, email, password, or confirmed password, which
reduces the risk of exposing personal information. Since my app currently uses
a mock service, no request is sent to a proxy or AI model. If a live service is
added later, its security and data-handling practices would still be a
remaining risk.

### 2. Failure and content fallback

**Question:** What should the UI do for timeout, invalid JSON, empty output, or
unsafe/unhelpful AI content? Explain your chosen fallback.

While requesting advice, my app displays a loading indicator and prevents
duplicate requests. For a timeout, invalid response, or empty result, it shows
a friendly error and provides a Retry button. Signup validation continues
working even when the advice service fails. Advice is displayed as plain text,
but this does not detect harmful content, so a live version should also check
the response for unsafe or unhelpful advice.

### 3. Design trade-off and improvement

**Question:** Describe one trade-off in your design and a practical
improvement.

I chose a mock service because it is predictable, private, and works without an
internet connection. The trade-off is that it cannot demonstrate real AI
response quality, delays, or network reliability. A practical improvement
would be to connect the same service interface to the instructor's approved
endpoint when it becomes available. I would then test both successful responses
and real connection failures.


