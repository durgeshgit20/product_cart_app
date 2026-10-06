# Performance Optimization

## The Core Loop: Minimize Rebuilds

Every unnecessary rebuild costs frame time. The hierarchy of defenses:

1. **`const` constructors** — widget is never rebuilt by the framework.
2. **`BlocBuilder` with `buildWhen`** — rebuild only when relevant state slice changes.
3. **`context.select()`** — subscribe to a single field on a Provider/Riverpod value.
4. **`Keys`** — tell Flutter which subtree maps to which widget across rebuilds.
5. **`RepaintBoundary`** — isolate frequent-painter widgets from the rest of the tree.

```dart
// const → zero rebuild cost
const Icon(Icons.home);

// buildWhen → rebuild only on count changes
BlocBuilder<CounterBloc, CounterState>(
  buildWhen: (prev, curr) => prev.count != curr.count,
  builder: (context, state) => Text('${state.count}'),
);
```

---

## Impeller (Default Renderer from Flutter 3.10+)

- Impeller replaces Skia on iOS (GA) and Android (opt-in on 3.22, GA later).
- Eliminates shader compilation jank by pre-compiling shaders at build time.
- Profile on **real devices** — simulator/emulator numbers are misleading.
- Use `flutter run --profile --enable-impeller` to test Impeller on Android.
- Report issues at github.com/flutter/flutter with label `impeller`.

---

## Lists & Large Datasets

| Approach | When |
|----------|------|
| `ListView.builder` | Long, homogeneous lists |
| `ListView.separated` | With dividers |
| `GridView.builder` | Grid layouts |
| `CustomScrollView` + Slivers | Mixed headers, grids, lists |
| `SliverList.builder` | Inside a `CustomScrollView` |
| `flutter_staggered_grid_view` | Variable height grid items |

```dart
// Correct: virtualized list
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, i) => ItemTile(key: ValueKey(items[i].id), item: items[i]),
);

// Wrong: renders ALL children at once
Column(children: items.map(ItemTile.new).toList());
```

---

## Image Optimization

- Use `cached_network_image` — caches to disk, not just memory.
- Specify `width` / `height` to prevent layout thrash.
- Use `Image.asset` with compressed assets (WebP preferred).
- For large images from disk, decode in an `Isolate` via `compute()`.
- Use `precacheImage(NetworkImage(url), context)` in `initState` for predictable loading.

```dart
CachedNetworkImage(
  imageUrl: user.avatarUrl,
  width: 48, height: 48,
  memCacheWidth: 96, // 2× for hi-DPI
  placeholder: (_, __) => const CircularProgressIndicator.adaptive(),
  errorWidget:  (_, __, ___) => const Icon(Icons.person),
);
```

---

## Isolates for CPU-Intensive Work

```dart
// Simple: use compute() for one-shot work
final result = await compute(_heavyParse, rawData);

// Advanced: long-lived Isolate with SendPort/ReceivePort
final rx = ReceivePort();
await Isolate.spawn(_workerEntry, rx.sendPort);
final tx = await rx.first as SendPort;
```

---

## Frame Rendering Targets

| Target | When |
|--------|------|
| 60 fps | Standard devices |
| 90 / 120 fps | ProMotion / high-refresh displays |
| 16ms per frame | Budget for all UI + raster work |
| < 8ms UI thread | Leave headroom for raster/GPU |

Use **Flutter DevTools → Performance** tab to identify:
- Jank frames (> 16ms)
- Expensive `build()` calls
- Shader compilation pauses (pre-Impeller)
- Excessive garbage collection

---

## Build & Bundle Size

- Enable `--split-debug-info` and `--obfuscate` for release builds.
- Use `flutter build apk --analyze-size` / `--split-per-abi` for Android.
- Remove unused assets from `pubspec.yaml`; use `flutter_gen` for type-safe asset access.
- Enable deferred loading (`loadLibrary()`) for rarely-used routes on web.
