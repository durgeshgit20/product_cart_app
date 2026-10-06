# Navigation, Routing & Push Notifications

## GoRouter (Mandatory)

All routing MUST use `go_router` — declarative, type-safe, deep-link–aware.

### Key Features to Use

| Feature | When |
|---------|------|
| `redirect` guards | Protect routes based on auth state |
| `StatefulShellRoute` | Bottom nav tabs with preserved per-tab state |
| Named routes + `TypedGoRoute` | Compile-time path/query parameter safety |
| `GoRouterObserver` | Screen view tracking for analytics |
| `GoRouter.of(context).go()` | Programmatic imperative navigation |

### Minimal Setup

```dart
final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = getIt<AuthBloc>().state is AuthSuccess;
    final isOnLogin  = state.matchedLocation == '/login';
    if (!isLoggedIn && !isOnLogin) return '/login';
    if (isLoggedIn  && isOnLogin)  return '/';
    return null;
  },
  observers: [AnalyticsObserver(getIt<AnalyticsService>())],
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/item/:id',
      builder: (_, state) => ItemScreen(id: state.pathParameters['id']!),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => ScaffoldWithNav(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/home', ...)]),
        StatefulShellBranch(routes: [GoRoute(path: '/profile', ...)]),
      ],
    ),
  ],
);
```

### Type-Safe Routes (GoRouter ≥ 7)

```dart
@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData {
  @override Widget build(BuildContext context, GoRouterState state) =>
      const HomeScreen();
}
```

---

## Deep Linking & Universal Links

- GoRouter handles deep links automatically when `initialLocation` and redirect guards are set up.
- Configure `AndroidManifest.xml` intent filters (App Links) and `ios/Runner/Info.plist` Associated Domains.
- Test deep links locally: `adb shell am start -W -a android.intent.action.VIEW -d "https://app.example.com/item/42"`.

---

## Context After Navigation

```dart
// ❌ context may be invalid after async navigation
await showDialog(...);
context.go('/next'); // crash if widget unmounted

// ✅ guard with mounted
await showDialog(...);
if (!mounted) return;
context.go('/next');
```

---

## Push Notifications — FCM + APNs (Standard)

- Centralized `NotificationService` registered as `@lazySingleton` in GetIt.
- Deep link routing via GoRouter on notification tap.

### Lifecycle Handlers

```dart
@lazySingleton
class NotificationService {
  Future<void> initialize(GoRouter router) async {
    await FirebaseMessaging.instance.requestPermission();

    // Foreground
    FirebaseMessaging.onMessage.listen((msg) => _showInAppBanner(msg));

    // Tapped while app in background
    FirebaseMessaging.onMessageOpenedApp.listen(
      (msg) => _navigate(router, msg),
    );

    // App launched by tapping a notification (terminated state)
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _navigate(router, initial);
  }

  void _navigate(GoRouter router, RemoteMessage msg) {
    final path = msg.data['deep_link'] as String?;
    if (path != null) router.go(path);
  }
}
```

### Platform Config Checklist

| Platform | Required config |
|----------|----------------|
| Android | `google-services.json`, notification channel in `Application.onCreate` |
| iOS | `GoogleService-Info.plist`, APNs key in Firebase console, background mode enabled |

---

## Local Notifications

Use `flutter_local_notifications` for scheduled, repeating, or rich local alerts. Always cancel notifications from `dispose` or when user logs out.
