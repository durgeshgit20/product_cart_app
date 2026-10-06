# State Management & Dependency Injection

## BLoC / Cubit (Primary — Mandatory)

- All business logic MUST use BLoC or Cubit from `flutter_bloc`.
- States and Events MUST be modeled as Dart 3 `sealed` classes for exhaustive `switch` handling.
- Use `package:bloc_concurrency` event transformers:
  - `droppable()` — ignore new events while one is processing
  - `restartable()` — cancel the current handler and restart on new event
  - `sequential()` — queue events and process one at a time
- Use `BlocListener` / `BlocConsumer` for side effects (navigation, snackbars, logging).
- Use `HydratedBloc` when state persistence across app restarts is needed.
- Every BLoC MUST have corresponding `blocTest` unit tests verifying state emission sequences.

### Common Pitfalls

| Pitfall | Risk | Fix |
|---------|------|-----|
| `emit()` after `close()` | Crash | Check `isClosed` before emitting |
| Missing `sealed` on states | Incomplete switch | Always use `sealed class` |
| No event transformer | Race conditions | Use `bloc_concurrency` |
| Bloc created inside `build` | New instance on rebuild | Create in `BlocProvider` or via DI |

### Minimal Example

```dart
// events
sealed class AuthEvent {}
final class LoginRequested extends AuthEvent {
  final String email, password;
  LoginRequested(this.email, this.password);
}

// states
sealed class AuthState {}
final class AuthInitial extends AuthState {}
final class AuthLoading extends AuthState {}
final class AuthSuccess extends AuthState { final User user; AuthSuccess(this.user); }
final class AuthFailure extends AuthState { final String message; AuthFailure(this.message); }

// bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  AuthBloc(this._repo) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin, transformer: droppable());
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _repo.login(event.email, event.password);
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user)    => emit(AuthSuccess(user)),
    );
  }
}
```

---

## Dependency Injection — GetIt + Injectable (Mandatory)

- Use `get_it` as the Service Locator for all dependency registration.
- Use `injectable` + `injectable_generator` for code-generated DI setup.
- Register services based on lifecycle:
  - `@singleton` — one instance, eagerly created
  - `@lazySingleton` — one instance, created on first use
  - `@injectable` — new instance every time (factory)
- Use `@Environment('staging')` / `@Environment('production')` for env-specific registrations.
- All repositories and data sources MUST be registered through GetIt — never instantiate directly in UI.

### Setup Example

```dart
// injection.dart
@InjectableInit()
void configureDependencies(String env) =>
    getIt.init(environment: env);

// repository
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository { ... }

// bloc — factory so each screen gets a fresh instance
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthRepository repo) : super(AuthInitial());
}
```

---

## Other State Management Options

| Solution | When to use |
|----------|-------------|
| **Riverpod 2.x** | Complex cross-feature reactive state, compile-time safety needed |
| **Provider** | Simple, lightweight state sharing within a single feature |
| Custom `ChangeNotifier` | Tiny widgets or proof-of-concept |

Always prefer BLoC/Cubit for production code.
