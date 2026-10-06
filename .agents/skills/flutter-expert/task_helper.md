# Flutter Expert Task Helper

When starting a new feature or task, tag this file (`@task_helper.md`) to ensure we follow the established workflow.

## 1. Task Classification

Please provide details about the task, covering any of the applicable layers:

- **Domain**: Are there specific business rules or use cases?
- **Data**: What data sources are involved? (Please provide the API `curl` or JSON response model if network requests are needed).
- **UI**: Are there any specific Figma designs, widgets, or state management complexities? (Please provide the Figma node link or ID).
- **Other**: Any navigation (GoRouter), dependencies, or core setup involved?

## 2. API Details

If this feature requires fetching or submitting data to an API, please provide:

- The exact API endpoint or `curl` command.
- The expected request payload and response JSON model.

## 3. Figma Design Details

If this feature involves UI implementation or visual updates, please provide:

- The exact Figma node link or node ID.
- Any specific interactive functionality, animations, or hidden states expected from the design.

## 4. Project Architecture & Patterns

We are following:

- Clean Architecture with **Functional Programming** (using `fpdart` and `EitherResponse`).
- Dependency Injection (GetIt / Injectable).
- State Management (BLoC / Cubit).
- Navigation (GoRouter).

## 5. UI Components & Widget Strategy

- We reuse existing project widgets before building new ones.
  - If reusable across features, new widgets go into a shared widgets folder.
  - If highly specific and non-reusable, we create new widgets localized only for this feature.

## Open Questions From AI

To help me assist you better, I will first ask any clarifying open questions about edge cases, loading states, error handling, or design preferences before we start coding. Let me know if you have specific preferences!
