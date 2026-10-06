# Widgets, UI & Dart Language

## Core Flutter Widget Mastery

- Prefer **composition over inheritance** — build small, focused widgets.
- Use `const` constructors for every widget that doesn't depend on runtime data.
- Use `Key` (especially `ValueKey` / `ObjectKey`) on list children so Flutter can track identity across rebuilds.
- Never put business logic inside `build()` — delegate to BLoC/Cubit.
- Keep `build()` pure and cheap; it can be called many times.

### UI Components & Widget Strategy

- **Reuse first**: Before building UI, check whether a suitable widget already exists in the project.
- **Missing Widgets Strategy**:
  - If the widget is reusable across features, place it in a shared widgets folder.
  - If highly specific and non-reusable, create new localized widgets only for the feature itself.

### Widget Lifecycle (StatefulWidget)

```
createState() → initState() → didChangeDependencies() → build()
                                                           ↓
                                              setState() → build()
                                                           ↓
                                           didUpdateWidget() → build()
                                                           ↓
                                                      deactivate()
                                                           ↓
                                                       dispose()
```

| Hook | Use for |
|------|---------|
| `initState` | One-time setup, subscribe to streams, init controllers |
| `didChangeDependencies` | Respond to `InheritedWidget` changes, safe to use `context` |
| `didUpdateWidget` | React to parent passing new widget props |
| `dispose` | Cancel streams, close controllers, remove listeners |

### Common Pitfalls

| Pitfall | Risk | Fix |
|---------|------|-----|
| GlobalKey used for state access | Performance hit | Pass callbacks / use BLoC |
| Missing key on dynamic list | State mismatch | Always use `ValueKey(item.id)` |
| Heavy work in `build` | Jank | Move to `initState` or BLoC |
| `InheritedWidget` misuse | Unexpected rebuilds | Use `select()` on BlocBuilder |

---

## BuildContext Rules

- **Never use `context` after an `await`** without checking `mounted` first.
- `context` is only valid for the widget it belongs to — don't store and reuse across rebuilds.
- Use `context.read<MyBloc>()` (no rebuild) vs `context.watch<MyBloc>()` (triggers rebuild).

```dart
Future<void> _save() async {
  await repository.save(data);
  if (!mounted) return; // ← guard
  context.go('/success');
}
```

---

## Custom Widget Patterns

### Render Objects
Use `CustomPainter` for 2D drawing; use full `RenderObject` only when layout/hit-testing customization is needed.

```dart
class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) { ... }

  @override bool shouldRepaint(_ChartPainter old) => old.data != data;
}
```

### Slivers
Use `SliverList`, `SliverGrid`, and `SliverAppBar` for efficient, scroll-integrated layouts.

---

## Advanced UI & Animations

| Technique | Best for |
|-----------|---------|
| `AnimationController` + `Tween` | Full custom control, multi-stage animations |
| `AnimatedBuilder` | Rebuilds only the animating subtree |
| Implicit animations (`AnimatedContainer`, `AnimatedOpacity`) | Simple property changes |
| Hero | Shared element transitions across routes |
| `TickerProviderStateMixin` | Multiple controllers in one widget |
| Rive / Lottie | Designer-driven vector animations |

```dart
class _FadeWidget extends StatefulWidget { ... }
class _FadeWidgetState extends State<_FadeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

  @override void dispose() { _ctrl.dispose(); super.dispose(); }
}
```

---

## Dart 3 Language Features

| Feature | Use |
|---------|-----|
| `sealed class` | Exhaustive switch on states/events |
| Records `(int, String)` | Lightweight value tuples |
| Pattern matching (`switch`, `if-case`) | Destructure sealed classes cleanly |
| `final` in patterns | Immutable destructured values |
| Extension methods | Add behaviour to third-party types |
| Mixins | Share capabilities without inheritance |
| `late` | Lazy init for non-nullable fields initialized in `initState` |
| `typedef` | Named function signatures for callbacks |

### Pattern Matching Example

```dart
switch (state) {
  case AuthLoading()  => const CircularProgressIndicator(),
  case AuthSuccess(:final user) => Text('Hello ${user.name}'),
  case AuthFailure(:final message) => Text(message, style: errorStyle),
  case AuthInitial() => const SizedBox.shrink(),
}
```

---

## Responsive & Adaptive Design

```dart
// Responsive breakpoints
Widget build(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return switch (width) {
    < 600  => const MobileLayout(),
    < 1200 => const TabletLayout(),
    _      => const DesktopLayout(),
  };
}

// Or with LayoutBuilder for parent-relative sizing
LayoutBuilder(builder: (context, constraints) {
  if (constraints.maxWidth < 600) return const MobileLayout();
  return const WideLayout();
});
```

---

## Material Design 3 & Theming

- Use `ThemeData.colorScheme` tokens — avoid hardcoded colours.
- Define typography via `TextTheme`; reference via `Theme.of(context).textTheme`.
- Apply `useMaterial3: true` in `MaterialApp`.
- Design system components MUST be tested with golden files.
