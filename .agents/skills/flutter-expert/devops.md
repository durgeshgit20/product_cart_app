# DevOps, CI/CD, Analytics & Observability

## CI/CD — CodeMagic (Mandatory)

CodeMagic is the **only** CI/CD platform for our projects.

### Pipeline Responsibilities

| Stage | What happens |
|-------|-------------|
| **Build** | `flutter build appbundle --flavor staging` |
| **Test** | `flutter test`, `bloc_test`, golden tests |
| **Sign** | Certificates managed in CodeMagic Teams |
| **Distribute (staging)** | Firebase App Distribution / TestFlight |
| **Distribute (production)** | App Store Connect + Google Play Console |

### Flavors / Environments

```yaml
# codemagic.yaml snippet
workflows:
  staging:
    environment:
      flutter: stable
      vars:
        FLAVOR: staging
    scripts:
      - flutter test
      - flutter build appbundle --flavor staging --dart-define=ENV=staging
  production:
    scripts:
      - flutter test
      - flutter build appbundle --flavor production --dart-define=ENV=production
```

### Local Flavor Commands

```bash
# Run staging
flutter run --flavor staging --dart-define=ENV=staging

# Build production
flutter build appbundle --flavor production --release \
  --dart-define=ENV=production \
  --obfuscate --split-debug-info=build/debug-info
```

---

## Git & Commit Standards (Mandatory)

Strict **Conventional Commits** on every commit:

| Prefix | When |
|--------|------|
| `feat(scope):` | New user-facing feature |
| `fix(scope):` | Bug fix |
| `refactor(scope):` | Code change with no behaviour change |
| `perf(scope):` | Performance improvement |
| `test(scope):` | Add / update tests |
| `docs(scope):` | Documentation only |
| `chore(scope):` | Build system, deps, tooling |
| `ci(scope):` | CI/CD config changes |
| `style(scope):` | Formatting, no logic change |

Examples:
```
feat(auth): add biometric login with fallback PIN
fix(home): resolve list scroll jank on Android 12
perf(feed): cache network images with LRU eviction
test(auth): add blocTest for LoginRequested event
```

- **Atomic commits** — one logical change per commit.
- PR descriptions must reference the Jira ticket and describe the "why".

---

## Analytics — Composite Multi-Provider

> **Pattern**: Composite + Adapter. The app calls one `AnalyticsService`.
> That service fans out to every registered `AnalyticsAdapter`.
> Adding a new provider (e.g. Amplitude) = implement one interface + register it.
> Zero changes to call sites.

---

### Architecture

```
┌──────────────────────────────────┐
│  App code / BLoC                 │
│  getIt<AnalyticsService>()       │
└────────────┬─────────────────────┘
             │ calls
             ▼
┌──────────────────────────────────┐
│  CompositeAnalyticsService       │  ← registered as AnalyticsService
│  (fans out to all adapters)      │
└──┬──────────┬────────────┬───────┘
   │          │            │
   ▼          ▼            ▼
Mixpanel  GoogleAnalytics  ...future
Adapter   Adapter          Adapter
```

---

### Step 1 — Adapter Interface

Every provider implements this single contract:

```dart
// lib/core/analytics/analytics_adapter.dart
abstract class AnalyticsAdapter {
  /// Called once at app start. Use for SDK init.
  Future<void> init();

  /// Identify a user; called after login.
  Future<void> identify(String userId, {Map<String, dynamic>? traits});

  /// Track a discrete event.
  Future<void> logEvent(String name, {Map<String, dynamic>? properties});

  /// Track a screen view.
  Future<void> setScreen(String screenName);

  /// Set a persistent user property.
  Future<void> setUserProperty(String name, dynamic value);

  /// Clear identity; called on logout.
  Future<void> reset();
}
```

---

### Step 2 — App-Facing Service (the composite)

This is the only class the rest of the app ever sees:

```dart
// lib/core/analytics/analytics_service.dart
abstract class AnalyticsService implements AnalyticsAdapter {}

@LazySingleton(as: AnalyticsService)
class CompositeAnalyticsService implements AnalyticsService {
  final List<AnalyticsAdapter> _adapters;

  // GetIt injects ALL AnalyticsAdapter registrations as a list
  CompositeAnalyticsService(@Named('analyticsAdapters') this._adapters);

  @override
  Future<void> init() =>
      Future.wait(_adapters.map((a) => a.init()));

  @override
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) =>
      Future.wait(_adapters.map((a) => a.identify(userId, traits: traits)));

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? properties}) =>
      Future.wait(_adapters.map((a) => a.logEvent(name, properties: properties)));

  @override
  Future<void> setScreen(String screenName) =>
      Future.wait(_adapters.map((a) => a.setScreen(screenName)));

  @override
  Future<void> setUserProperty(String name, dynamic value) =>
      Future.wait(_adapters.map((a) => a.setUserProperty(name, value)));

  @override
  Future<void> reset() =>
      Future.wait(_adapters.map((a) => a.reset()));
}
```

---

### Step 3 — Adapters

#### Mixpanel Adapter

```dart
// lib/core/analytics/adapters/mixpanel_analytics_adapter.dart
@Injectable(as: AnalyticsAdapter)
class MixpanelAnalyticsAdapter implements AnalyticsAdapter {
  late final Mixpanel _mp;

  @override
  Future<void> init() async {
    _mp = await Mixpanel.init(
      Env.mixpanelToken,
      trackAutomaticEvents: true,
    );
    if (kDebugMode) _mp.setLoggingEnabled(true);
  }

  @override
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    _mp.identify(userId);
    traits?.forEach((k, v) => _mp.getPeople().set(k, v));
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? properties}) async {
    _mp.track(name, properties: properties);
  }

  @override
  Future<void> setScreen(String screenName) async {
    _mp.track('Screen Viewed', properties: {'screen_name': screenName});
  }

  @override
  Future<void> setUserProperty(String name, dynamic value) async {
    _mp.getPeople().set(name, value);
  }

  @override
  Future<void> reset() async => _mp.reset();
}
```

#### Google Analytics (Firebase) Adapter

```dart
// lib/core/analytics/adapters/google_analytics_adapter.dart
@Injectable(as: AnalyticsAdapter)
class GoogleAnalyticsAdapter implements AnalyticsAdapter {
  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  @override Future<void> init() async {} // initialized by Firebase.initializeApp()

  @override
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    await _fa.setUserId(id: userId);
    if (traits != null) {
      for (final entry in traits.entries) {
        await _fa.setUserProperty(name: entry.key, value: entry.value.toString());
      }
    }
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? properties}) =>
      _fa.logEvent(name: name, parameters: properties?.cast<String, Object>());

  @override
  Future<void> setScreen(String screenName) =>
      _fa.logScreenView(screenName: screenName);

  @override
  Future<void> setUserProperty(String name, dynamic value) =>
      _fa.setUserProperty(name: name, value: value.toString());

  @override Future<void> reset() async {} // Firebase GA has no user reset API
}
```

#### Adding a Future Provider (e.g. Amplitude)

```dart
// lib/core/analytics/adapters/amplitude_analytics_adapter.dart
@Injectable(as: AnalyticsAdapter)         // ← only line that wires it in
class AmplitudeAnalyticsAdapter implements AnalyticsAdapter {
  @override Future<void> init()    async { /* Amplitude init */ }
  @override Future<void> identify(String id, {Map<String, dynamic>? traits}) async { ... }
  @override Future<void> logEvent(String name, {Map<String, dynamic>? p})    async { ... }
  @override Future<void> setScreen(String s)                                  async { ... }
  @override Future<void> setUserProperty(String n, dynamic v)                 async { ... }
  @override Future<void> reset()   async { ... }
}
// Done — CompositeAnalyticsService picks it up automatically.
```

---

### Step 4 — GetIt Registration

Use `registerFactoryMultiBindings` via the generated injection module:

```dart
// lib/core/analytics/analytics_module.dart
@module
abstract class AnalyticsModule {
  @Named('analyticsAdapters')
  List<AnalyticsAdapter> get adapters => [
    getIt<MixpanelAnalyticsAdapter>(),
    getIt<GoogleAnalyticsAdapter>(),
    // getIt<AmplitudeAnalyticsAdapter>(), ← uncomment to add
  ];
}
```

---

### Event Naming Convention

```
<object>_<action>          ← snake_case, noun-verb

authentication_login_attempted
authentication_login_succeeded
authentication_login_failed
appointment_booked
prescription_viewed
onboarding_step_completed
```

- **Never include PII** (names, emails, DOBs) in event names or property values.
- Version events on schema change: `appointment_booked_v2`.
- Use constants, not raw strings: `AnalyticsEvents.appointmentBooked`.

---

### GoRouter Screen Tracking

```dart
class AnalyticsRouteObserver extends NavigatorObserver {
  final AnalyticsService _analytics;
  AnalyticsRouteObserver(this._analytics);

  @override
  void didPush(Route route, Route? previousRoute) {
    final name = route.settings.name;
    if (name != null) _analytics.setScreen(name);
  }
}

GoRouter(
  observers: [AnalyticsRouteObserver(getIt<AnalyticsService>())],
)
```

---

### Identity Lifecycle

```dart
// After login — identify across ALL adapters simultaneously
await getIt<AnalyticsService>().identify(user.id, traits: {
  r'$name':  user.displayName, // Mixpanel reserved
  r'$email': user.email,
  'plan':    user.subscriptionPlan,
  'role':    user.role,
});

// After logout — reset ALL adapters
await getIt<AnalyticsService>().reset();
```

---

## Crash & Error Management — Composite Multi-Provider

> **Pattern**: same Composite + Adapter as Analytics.
> The app calls one `CrashService`. It fans out to every `CrashReporter`.
> To add Datadog, BugSnag, etc. — implement one interface and register it.

---

### Architecture

```
┌──────────────────────────────────┐
│  App code / BLocObserver / main  │
│  getIt<CrashService>()           │
└────────────┬─────────────────────┘
             │ calls
             ▼
┌──────────────────────────────────┐
│  CompositeCrashService           │  ← registered as CrashService
│  (fans out to all reporters)     │
└──┬──────────┬────────────┬───────┘
   │          │            │
   ▼          ▼            ▼
Sentry    Crashlytics   ...future
Reporter  Reporter      Reporter
```

---

### Error Classification

| Level | Definition | What to call |
|-------|------------|------------------|
| **Fatal** | Unrecoverable crash | `recordError(fatal: true)` |
| **Non-fatal** | Handled error, degraded UX | `recordError(fatal: false)` |
| **Warning** | Unexpected but recoverable | `recordError` + severity hint in extras |
| **Breadcrumb** | State transition, low-signal context | `addBreadcrumb` |

---

### Step 1 — Reporter Interface

```dart
// lib/core/crash/crash_reporter.dart
abstract class CrashReporter {
  Future<void> init();

  void recordFlutterError(FlutterErrorDetails details);

  Future<void> recordError(
    Object error,
    StackTrace stack, {
    String? context,
    bool fatal = false,
    Map<String, dynamic>? extras,
  });

  void addBreadcrumb(String message, {Map<String, dynamic>? data});

  void setUser(String id, {String? email, String? name});

  void clearUser();
}
```

---

### Step 2 — App-Facing Service (the composite)

```dart
// lib/core/crash/crash_service.dart
abstract class CrashService implements CrashReporter {}

@LazySingleton(as: CrashService)
class CompositeCrashService implements CrashService {
  final List<CrashReporter> _reporters;

  CompositeCrashService(@Named('crashReporters') this._reporters);

  @override
  Future<void> init() =>
      Future.wait(_reporters.map((r) => r.init()));

  @override
  void recordFlutterError(FlutterErrorDetails details) {
    for (final r in _reporters) {
      r.recordFlutterError(details);
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    String? context,
    bool fatal = false,
    Map<String, dynamic>? extras,
  }) =>
      Future.wait(_reporters.map((r) => r.recordError(
        error, stack,
        context: context,
        fatal: fatal,
        extras: extras,
      )));

  @override
  void addBreadcrumb(String message, {Map<String, dynamic>? data}) {
    for (final r in _reporters) {
      r.addBreadcrumb(message, data: data);
    }
  }

  @override
  void setUser(String id, {String? email, String? name}) {
    for (final r in _reporters) {
      r.setUser(id, email: email, name: name);
    }
  }

  @override
  void clearUser() {
    for (final r in _reporters) {
      r.clearUser();
    }
  }
}
```

---

### Step 3 — Reporters

#### Sentry Reporter

```dart
// lib/core/crash/reporters/sentry_crash_reporter.dart
@Injectable(as: CrashReporter)
class SentryCrashReporter implements CrashReporter {
  @override
  Future<void> init() async {
    // SentryFlutter.init() is called in main() — nothing extra needed here.
    // Disable in debug to avoid noise.
    await Sentry.configureScope((s) {
      if (kDebugMode) s.level = SentryLevel.warning;
    });
  }

  @override
  void recordFlutterError(FlutterErrorDetails details) {
    // SentryFlutter.init automatically hooks FlutterError — this is a passthrough.
    Sentry.captureException(details.exception, stackTrace: details.stack);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    String? context,
    bool fatal = false,
    Map<String, dynamic>? extras,
  }) =>
      Sentry.captureException(
        error,
        stackTrace: stack,
        withScope: (scope) {
          scope.level = fatal ? SentryLevel.fatal : SentryLevel.error;
          if (context != null) scope.setTag('context', context);
          extras?.forEach((k, v) => scope.setExtra(k, v));
        },
      );

  @override
  void addBreadcrumb(String message, {Map<String, dynamic>? data}) {
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      data: data,
      timestamp: DateTime.now().toUtc(),
    ));
  }

  @override
  void setUser(String id, {String? email, String? name}) {
    Sentry.configureScope(
      (s) => s.setUser(SentryUser(id: id, email: email, name: name)),
    );
  }

  @override
  void clearUser() => Sentry.configureScope((s) => s.setUser(null));
}
```

#### Crashlytics Reporter

```dart
// lib/core/crash/reporters/crashlytics_reporter.dart
@Injectable(as: CrashReporter)
class CrashlyticsReporter implements CrashReporter {
  @override
  Future<void> init() async {
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  @override
  void recordFlutterError(FlutterErrorDetails details) =>
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    String? context,
    bool fatal = false,
    Map<String, dynamic>? extras,
  }) =>
      FirebaseCrashlytics.instance.recordError(
        error, stack,
        reason: context,
        fatal: fatal,
        information: extras?.entries
            .map((e) => '${e.key}: ${e.value}')
            .toList() ?? [],
      );

  @override
  void addBreadcrumb(String message, {Map<String, dynamic>? data}) {
    FirebaseCrashlytics.instance.log(
      data != null ? '$message | $data' : message,
    );
  }

  @override
  void setUser(String id, {String? email, String? name}) =>
      FirebaseCrashlytics.instance.setUserIdentifier(id);

  @override
  void clearUser() => FirebaseCrashlytics.instance.setUserIdentifier('');
}
```

#### Adding a Future Reporter (e.g. Datadog)

```dart
// lib/core/crash/reporters/datadog_reporter.dart
@Injectable(as: CrashReporter)           // ← only line that wires it in
class DatadogReporter implements CrashReporter {
  @override Future<void> init()                                              async { ... }
  @override void   recordFlutterError(FlutterErrorDetails d)                       { ... }
  @override Future<void> recordError(Object e, StackTrace s, {...})          async { ... }
  @override void   addBreadcrumb(String msg, {Map<String, dynamic>? data})        { ... }
  @override void   setUser(String id, {String? email, String? name})               { ... }
  @override void   clearUser()                                                     { ... }
}
// Done — CompositeCrashService picks it up automatically.
```

---

### Step 4 — GetIt Registration

```dart
// lib/core/crash/crash_module.dart
@module
abstract class CrashModule {
  @Named('crashReporters')
  List<CrashReporter> get reporters => [
    getIt<SentryCrashReporter>(),
    getIt<CrashlyticsReporter>(),
    // getIt<DatadogReporter>(), ← uncomment to add
  ];
}
```

---

### Step 5 — Bootstrap in `main()`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await SentryFlutter.init(
    (options) {
      options.dsn                    = Env.sentryDsn;
      options.environment            = Env.name;      // 'staging' | 'production'
      options.release                = '${Env.appVersion}+${Env.buildNumber}';
      options.tracesSampleRate       = kDebugMode ? 0.0 : 0.2;
      options.attachScreenshot       = true;
      options.attachViewHierarchy    = true;
      options.enableAutoSessionTracking = true;
    },
    appRunner: () async {
      configureDependencies(Env.name);

      // Init ALL reporters (Sentry + Crashlytics + any future ones)
      await getIt<CrashService>().init();

      // Init ALL analytics adapters
      await getIt<AnalyticsService>().init();

      // Global error hooks — both flow into CompositeCrashService
      FlutterError.onError = (details) {
        getIt<CrashService>().recordFlutterError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        getIt<CrashService>().recordError(error, stack, fatal: true);
        return true;
      };

      Bloc.observer = AppBlocObserver(
        crash:     getIt<CrashService>(),
        analytics: getIt<AnalyticsService>(),
      );

      runApp(const MyApp());
    },
  );
}
```

---

### BlocObserver — Errors & Breadcrumbs

```dart
class AppBlocObserver extends BlocObserver {
  final CrashService     _crash;
  final AnalyticsService _analytics;

  AppBlocObserver({required CrashService crash, required AnalyticsService analytics})
      : _crash = crash, _analytics = analytics;

  @override
  void onError(BlocBase bloc, Object error, StackTrace stack) {
    _crash.recordError(
      error, stack,
      context: bloc.runtimeType.toString(),
      extras: {'state': bloc.state.runtimeType.toString()},
    );
    super.onError(bloc, error, stack);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    // Breadcrumb only — no PII
    _crash.addBreadcrumb(
      '${bloc.runtimeType}: '
      '${change.currentState.runtimeType} → ${change.nextState.runtimeType}',
    );
    super.onChange(bloc, change);
  }
}
```

---

### Error Handling Decision Tree

```
Error occurs
    │
    ├─ App crashes (uncaught) ──────────► FlutterError.onError / PlatformDispatcher
    │                                      → fatal: true → ALL reporters via composite
    │
    ├─ BLoC handler throws ─────────────► AppBlocObserver.onError
    │                                      → fatal: false → ALL reporters
    │
    ├─ Repository / API call fails ─────► catch in handler, emit Failure state
    │   • Network / timeout              → addBreadcrumb + recordError (non-fatal)
    │   • 4xx client error               → addBreadcrumb only
    │   • 5xx server error               → recordError (non-fatal)
    │
    └─ Validation / business-logic ─────► no crash reporting; show UI error only
```

---

### Breadcrumb Usage Patterns

```dart
// In repository — before a risky network call
getIt<CrashService>().addBreadcrumb(
  'Fetching appointments',
  data: {'patient_id': patientId, 'page': page},
);

// After login — propagates to ALL reporters
getIt<CrashService>().setUser(user.id, email: user.email, name: user.displayName);

// After logout — clears from ALL reporters
getIt<CrashService>().clearUser();
```

---

### Tool Responsibility Reference

| Task | Primary tool |
|------|--------------|
| Crash symbolication (iOS/Android) | Crashlytics |
| ANR & freeze detection | Crashlytics |
| Google Play Android Vitals | Crashlytics |
| Error aggregation & trends | Sentry |
| Performance tracing (API latency) | Sentry |
| Release health / error budgets | Sentry |
| Rich breadcrumb trails | Sentry |
| Screenshot on crash | Sentry |
| Alerting / PagerDuty integration | Sentry |

---

## Performance Monitoring

- Use **Sentry performance tracing** for API / DB operations (auto-instruments Dio via `SentryDioClientAdapter`).
- Use **Firebase Performance** for automatic cold/warm start traces.
- Always profile on real physical devices — never trust emulator numbers.

```dart
// Sentry transaction (wraps a user flow)
final transaction = Sentry.startTransaction('login_flow', 'task');
try {
  await _performLogin();
  transaction.status = const SpanStatus.ok();
} catch (e, st) {
  transaction.throwable = e;
  transaction.status    = const SpanStatus.internalError();
  rethrow;
} finally {
  await transaction.finish();
}

// Auto-instrument all Dio HTTP calls
final dio = Dio()..addSentryDioClientAdapter();
```


