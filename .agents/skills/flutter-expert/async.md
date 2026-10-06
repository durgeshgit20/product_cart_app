# Async Patterns, Dispose & Data Persistence

## Async / Await Rules

- **Always check `mounted` after any `await`** before using `BuildContext`.
- **Always check `isClosed` in a BLoC** before calling `emit()` after an `await`.
- Prefer `Emitter<S>` inside BLoC handlers — it handles closed-bloc safety for you.

```dart
// ❌ Dangerous
Future<void> _onLoad(LoadEvent e, Emitter<MyState> emit) async {
  final data = await repo.fetch();
  emit(Loaded(data)); // might be closed
}

// ✅ Safe via Emitter (preferred in BLoC)
Future<void> _onLoad(LoadEvent e, Emitter<MyState> emit) async {
  await emit.forEach(
    repo.fetchStream(),
    onData: (data) => Loaded(data),
    onError: (e, st) => Failed(e.toString()),
  );
}
```

---

## FutureBuilder & StreamBuilder

| Trap | Fix |
|------|-----|
| Future re-created every parent rebuild | Cache Future in `initState` or BLoC |
| No `hasError` branch | Always handle `snapshot.hasError` |
| ConnectionState.waiting not shown | Show loading indicator |
| Stream not cancelled | Use `StreamSubscription` and cancel in `dispose` |

```dart
// Cache the future — never create inside build()
class _MyWidgetState extends State<MyWidget> {
  late final Future<List<Item>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ItemBloc>().fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        return ItemList(items: snapshot.requireData);
      },
    );
  }
}
```

---

## Dispose Checklist

Every `StatefulWidget` **must** dispose:

| Resource | How to dispose |
|----------|---------------|
| `AnimationController` | `_ctrl.dispose()` |
| `TextEditingController` | `_tec.dispose()` |
| `ScrollController` | `_sc.dispose()` |
| `FocusNode` | `_fn.dispose()` |
| `StreamSubscription` | `_sub.cancel()` |
| `Timer` | `_timer.cancel()` |
| `PageController` | `_pc.dispose()` |

```dart
@override
void dispose() {
  _animationController.dispose();
  _textController.dispose();
  _scrollController.dispose();
  _subscription.cancel();
  super.dispose(); // ← always last
}
```

---

## Streams & Isolates

- Use `Isolate` / `compute()` for CPU-heavy work (parsing large JSON, image processing).
- Use `Stream.periodic` + `StreamSubscription` for polling; cancel in `dispose`.
- Prefer `emit.forEach()` inside BLoC event handlers over raw `StreamSubscription`.

```dart
// Isolate for heavy JSON parsing
final parsed = await compute(_parseJson, rawJsonString);

List<Item> _parseJson(String json) =>
    (jsonDecode(json) as List).map(Item.fromJson).toList();
```

---

## Testing (Mandatory)

### BLoC Testing (blocTest)

```dart
blocTest<AuthBloc, AuthState>(
  'emits [Loading, Success] when login succeeds',
  build: () {
    when(() => mockRepo.login(any(), any()))
        .thenAnswer((_) async => Right(fakeUser));
    return AuthBloc(mockRepo);
  },
  act: (bloc) => bloc.add(LoginRequested('a@b.com', 'pass')),
  expect: () => [AuthLoading(), AuthSuccess(fakeUser)],
);
```

### Testing Stack

| Layer | Tool |
|-------|------|
| BLoC unit | `bloc_test` + `mocktail` |
| Repository unit | `mocktail` fake implementations |
| Widget | `testWidgets` + `find` semantics |
| Design system | Golden file tests |
| Integration / E2E | `patrol` |

---

## Data Persistence

| Need | Package | Notes |
|------|---------|-------|
| Key-value prefs | `shared_preferences` | Not for sensitive data |
| Secure key-value | `flutter_secure_storage` | Keychain / Keystore backed |
| Relational DB | `drift` (type-safe SQL) | Reactive query streams |
| Document / fast NoSQL | `hive` or `objectbox` | No schema migrations needed |
| Network images (cached) | `cached_network_image` | Default `Image.network` doesn't persist |
| REST API | `dio` + interceptors | Auth, logging, retry |
| Offline-first sync | Custom + background isolate | Queue writes, replay on reconnect |

### Dio Setup with Interceptors

```dart
@lazySingleton
class ApiClient {
  final Dio _dio;
  ApiClient(AuthTokenService tokens)
      : _dio = Dio(BaseOptions(baseUrl: Env.apiBase)) {
    _dio.interceptors.addAll([
      AuthInterceptor(tokens),
      LogInterceptor(requestBody: true),
      RetryInterceptor(dio: _dio, retries: 3),
    ]);
  }
}
```
