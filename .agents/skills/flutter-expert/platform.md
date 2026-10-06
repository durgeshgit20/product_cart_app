# Platform Integration, Security & Advanced Features

## Platform Channel Patterns

Flutter communicates with native code via channels. Always **catch `PlatformException`**.

| Channel type | Use |
|-------------|-----|
| `MethodChannel` | Request/reply (most common) |
| `EventChannel` | Native-to-Dart stream (sensors, BLE events) |
| `BasicMessageChannel` | Low-level bidirectional |

```dart
// Dart side
const _channel = MethodChannel('com.example.biometric');

Future<bool> authenticateWithBiometrics() async {
  try {
    return await _channel.invokeMethod<bool>('authenticate') ?? false;
  } on PlatformException catch (e) {
    log('Biometric failed: ${e.message}');
    return false;
  }
}
```

```swift
// iOS — Swift
FlutterMethodChannel(name: "com.example.biometric", binaryMessenger: controller.binaryMessenger)
  .setMethodCallHandler { call, result in
    if call.method == "authenticate" {
      // LAContext biometric call
      result(true)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
```

---

## Platform-Specific Capabilities

| Platform | Key areas |
|----------|-----------|
| **iOS** | Swift channels, Cupertino widgets, App Store guidelines, APNs, In-App Purchase |
| **Android** | Kotlin channels, Material 3, Google Play policies, FCM, App Links |
| **Web** | PWA manifest, web workers, CORS, `dart:html` access, responsive layout |
| **Desktop (macOS/Windows/Linux)** | Window sizing, native menus, file system access, tray icons |
| **Embedded / IoT** | Custom embedder, minimal Flutter engine, BLE, GPIO via FFI |

---

## Null Safety Patterns

```dart
// Late initialization — only when value is guaranteed before use
late final AuthService _auth;

// Conditional access
final name = user?.displayName ?? 'Guest';

// Non-null assertion — only when you KNOW it's non-null
final token = response.data!['token'] as String;

// Collection null handling
final tags = item.tags?.whereType<String>().toList() ?? [];
```

---

## Security & Compliance

### Secure Storage

```dart
// Use flutter_secure_storage (Keychain on iOS, Keystore on Android)
final storage = FlutterSecureStorage();
await storage.write(key: 'access_token', value: token);
final token = await storage.read(key: 'access_token');
```

### Certificate Pinning (Dio)

```dart
(_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final client = HttpClient()
    ..badCertificateCallback = (_, __, ___) => false;
  SecurityContext()
    ..setTrustedCertificatesBytes(certBytes);
  return client;
};
```

### Security Checklist

| Area | Requirement |
|------|-------------|
| Secrets | Never commit to git; load from env/secrets manager |
| Auth tokens | Store in `flutter_secure_storage` only |
| Network | TLS 1.2+, certificate pinning for sensitive APIs |
| Biometric | Use `local_auth`; always fall back to PIN/password |
| Obfuscation | `--obfuscate --split-debug-info` on release builds |
| Root/jailbreak | Detect with `flutter_jailbreak_detection` if required |
| GDPR | Explicit consent, data deletion flow, minimal data collection |

---

## FFI (C/C++ Integration)

```dart
// Load native library
final lib = DynamicLibrary.open('libnative.so');
final nativeAdd = lib.lookupFunction<Int32 Function(Int32, Int32),
                                    int  Function(int,  int )>('add');
print(nativeAdd(3, 4)); // 7
```

Use Isolates when the native call is long-running to avoid blocking the UI thread.

---

## Advanced Features

### Machine Learning (TensorFlow Lite)

```dart
// Use tflite_flutter package
final interpreter = await Interpreter.fromAsset('model.tflite');
interpreter.run(inputTensor, outputTensor);
```

### Augmented Reality

- **iOS**: ARKit via `arkit_plugin`
- **Android**: ARCore via `ar_flutter_plugin`
- Use `UiKitView` / `AndroidView` to embed native AR views.

### BLE & IoT

```dart
// flutter_blue_plus
FlutterBluePlus.scan(timeout: const Duration(seconds: 5))
    .listen((result) => _onDeviceFound(result.device));
```

### Real-Time (WebSockets / Firebase)

```dart
// Raw WebSocket
final socket = await WebSocket.connect('wss://api.example.com/ws');
socket.listen(
  (msg) => _handleMessage(msg),
  onDone: _reconnect,
);

// Firestore real-time stream
FirebaseFirestore.instance.collection('records')
    .where('patientId', isEqualTo: id)
    .snapshots()
    .listen(_onRecordsChanged);
```

---

## Internationalization (i18n)

- Use Flutter's built-in `flutter_localizations` + ARB files via `flutter gen-l10n`.
- Never hardcode user-facing strings.
- Test RTL layouts with `debugDisableShadows` + `Directionality.of(context)`.
