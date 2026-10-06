## Agent skills

### Issue tracker

Issues and specs live in GitHub Issues (durgeshgit20/product_cart_app), managed via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Coding standards

All Flutter code follows the `flutter-expert` skill at `.agents/skills/flutter-expert/`. Read `SKILL.md` first, then the sub-files for the task at hand: `state.md` (BLoC, DI), `async.md` (async, dispose, persistence, testing), `widgets.md` and `performance.md` (UI). They cover the architecture (clean architecture, repository pattern), design patterns and coding standards.

Skip the parts that don't apply to this app: GoRouter (this app uses `Navigator`), CI/CD and push notifications, and asking for `curl`/Figma (the spec and tickets are the source of truth). Where a spec or ticket makes a decision, the spec wins.
