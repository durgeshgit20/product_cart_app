---
name: flutter-expert
slug: flutter-expert
version: 2.0.0
description: Build reliable Flutter apps avoiding state loss, widget rebuild traps, and async pitfalls.
risk: unknown
source: community
date_added: '2026-02-27'
metadata: {"clawdbot":{"emoji":"🐦","requires":{"bins":["flutter"]},"os":["linux","darwin","win32"]}}
---

## Use this skill when

- Working on Flutter / Dart tasks or workflows
- Needing guidance, best practices, or checklists for Flutter development

## Do not use this skill when

- The task is unrelated to Flutter
- You need a different domain or tool outside this scope

## Quick Reference

| Topic | File |
|-------|------|
| BLoC/Cubit, DI (GetIt), state loss, keys | `state.md` |
| Widget lifecycle, build context, custom widgets, animations | `widgets.md` |
| FutureBuilder, streams, dispose, mounted, persistence | `async.md` |
| GoRouter, deep links, push notifications | `navigation.md` |
| const, rebuilds, Impeller, profiling | `performance.md` |
| Platform channels, security, ML/AR/IoT | `platform.md` |
| CI/CD (CodeMagic), analytics, crash reporting | `devops.md` |

## Critical Rules

- `setState` after dispose — check `mounted` before calling, crashes otherwise
- Key missing on list items — reordering breaks state, always use keys
- FutureBuilder rebuilds on parent rebuild — triggers future again, cache the Future
- BuildContext after async gap — context may be invalid, check `mounted` first
- `const` constructor — prevents rebuilds, use for static widgets
- `StatefulWidget` recreated — key change or parent rebuild creates new state
- GlobalKey expensive — don't use just to access state, pass callbacks instead
- `dispose` incomplete — cancel timers, subscriptions, controllers
- Navigator.pop with result — returns Future, don't ignore errors
- ScrollController not disposed — memory leak
- Image caching — use `cached_network_image`, default doesn't persist
- PlatformException not caught — platform channel calls can throw
- **Functional Error Handling** — Use `fpdart` (`Either`, `TaskEither`) for all Data/Domain results to avoid try-catch leakage into the UI layer.

## Workspace Context

- **Feature Modules (Clean Architecture)**: `lib/features/<feature_name>/`, with sub-folders `/data`, `/domain` and `/presentation`.
- **Dependency Injection (GetIt / Injectable)**: `lib/core/di/injection.dart` (generated config in `lib/core/di/injection.config.dart`).
- **Shared code**: reuse existing core utilities and widgets before building new ones.

## Instructions

1. **Analyze requirements** for optimal Flutter architecture.
2. **Classify tasks** before beginning into the following structure:
   - **1. Domain**: Business rules, use cases.
   - **2. Data**: Repositories, models, network requests.
   - **3. UI**: Widgets, screens, BLoC/Cubit interaction.
   - **4. Other**: Navigation, package-related setup, utilities.
3. **Follow Project Architecture & Design Patterns**: Ensure adherence to the established project architecture (e.g., Clean Architecture, Modular design) and design patterns (BLoC, GoRouter, GetIt).
4. **API Integration Readiness**: For any action requiring data fetching or submission, explicitly ask the user for the `curl` command and/or the response model.
5. **Ask Open Questions**: Proactively ask open questions to clarify requirements, design patterns, or missing parts of the feature before proceeding with implementation.
6. Open the relevant sub-skill file(s) from the Quick Reference table above.
7. Apply best practices and validate outcomes.
8. Use BLoC/Cubit, GoRouter, and GetIt as the primary stack unless the task explicitly requires otherwise.
9. **Functional Programming**: Utilize `fpdart` for error handling in Repositories and UseCases. Return `EitherResponse<T>` (which is `TaskEither<Failure, T>`) for all asynchronous operations.
10. Always use null safety with Dart 3 features.
11. Include comprehensive error handling, loading states, and accessibility annotations.
