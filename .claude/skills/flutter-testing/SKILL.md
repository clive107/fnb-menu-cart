---
name: flutter-testing
description: Use when writing or reviewing Flutter tests in this repo (util, model, BLoC, or cubit tests) — covers bloc_test/mocktail setup, BLoC event & state coverage (props, StatusX, copyWith), state-assertion rules, error-path parity across sibling handlers, cubits, and verifying coverage.
---

# Flutter Testing Conventions

> **In this repo (fnb_menu_cart):**
> - There is no authentication, so status enums have no `tokenExpired` and there is no `InvalidTokenFailure`. Skip those cases in the coverage rules and examples.
> - There is no Sentry. The "unexpected exception" case still emits `failure` with a null failure; it just isn't reported anywhere.
> - Run tests with `flutter test` (or `fvm flutter test`).

Paths below are relative to the repo root. The worked examples linked below live in [`examples/`](examples/) beside this file — written against a hypothetical app (`package:example_app/...`), so their imports and paths don't match this repo (see [`examples/README.md`](examples/README.md)).

Use `bloc_test` + `mocktail` for BLoC tests. Use `flutter_test` only for model and util tests.

When a handler is matched with `any(named: 'foo')` on a custom type (a request/model), register a fallback in `setUpAll` — `registerFallbackValue(MockFooRequest())` (or a real instance) — otherwise mocktail throws at match time.

Assert side effects with `verify`/`verifyNever`: `verify(() => service.saveX(...)).called(1)` on the success path, and `verifyNever(() => service.fetch(...))` on already-loading / no-op guard paths that emit `[]`.

## BLoC event & state coverage

Put the tests for the bloc, its event, and its state all in one `bar_bloc_test.dart` file. The event and state are `part` files, so they share the bloc's import and don't get their own test file.

`blocTest` checks the states a bloc emits, but it never directly calls the event and state code — so these parts stay uncovered:

- event `props` getters
- `StatusX` extension getters (`isLoading`, `isSuccess`, …)
- `copyWith` paths that clear a field to `null`

To cover them, add plain `test()` groups (alongside the `blocTest` groups) for:

- **Events** — assert each event's `props`: empty for no-field events (`expect(GetNote().props, isEmpty)`), and that every field appears for events with data (`expect(UpdateNote(updateNoteRequest: request).props, [request])`).
  - If **every** event in the bloc overrides `props` (i.e. none are field-less), the abstract base class's own `props => []` never gets called and sits uncovered. Add a private no-op fixture that doesn't override `props` — `class _NoOpFooEvent extends FooEvent {}` — with a comment above the class and above the test explaining why it's there and that it should be removed if a field-less event is later added. See [examples/note_details/note_details_bloc_test.dart](examples/note_details/note_details_bloc_test.dart).
- **`StatusX` getters** — one `test` per getter, asserting it is `true` for its own status and `false` for every other status (guards against copy-paste errors like `isSuccess => this == failure`). Repeat for each status enum the state declares.
- **`copyWith`** — assert: no-arg call returns an equal state; each non-`Optional` field updates when passed; each `Optional` field updates with `Optional.set(value)`, clears to `null` with `Optional.set(null)`, and is preserved when omitted.

See [examples/update_note/update_note_bloc_test.dart](examples/update_note/update_note_bloc_test.dart) for the canonical structure — it covers the harder cases (an event carrying data, and a state with two status enums).

## State assertions

When asserting emitted states in BLoC tests (`expect`, `seed`, or a shared seed-builder like `seededState()`), always specify **every** property explicitly rather than relying on constructor defaults — Equatable compares all fields, so spelling them out keeps each state self-documenting.

Before considering a bloc test file done, re-read every `seed:`/`expect:` state literal you just wrote (including inside shared seed-builder helpers) against this rule — it's easy to copy an earlier, partial literal in the same file instead of re-deriving it, so treat this as a mandatory final pass, not a one-time check.

## Error-path parity across sibling handlers

**For handlers that follow the standard fetch shape,** sibling handlers with the same try/catch shape (e.g. `GetXList` and `GetNextXList`) need the same test set: success, `tokenExpired` (`InvalidTokenFailure`), `failure` (thrown `Failure`/`ClientException`), and `failure` with a null failure (plain `Exception` — the only case that hits `Sentry.captureException`), plus the already-loading guard if present. One sibling missing a case the other has is the most common coverage gap.

Some blocs legitimately differ — match the handler's actual catch structure rather than forcing the full set. For example, an authentication bloc that maps every error to `unauthenticated`/`sessionExpired` has no `InvalidTokenFailure` split.

Also test each branch of type-switching parsing helpers (`is int`, `is String`, fallback) separately — a `String`-branch test won't exercise the final fallback line.

## Cubits

Cubits have no events, status enum, or `copyWith`, so skip those `test()` groups. Test the emitted state directly: `blocTest` with `act` calling the cubit's methods, plus plain `test()`s for the initial state (including constructor params like `initialTab`) and any constructor callbacks. Close the cubit manually (`cubit.close()`) in plain tests. See [examples/base_tabs/base_tabs_cubit_test.dart](examples/base_tabs/base_tabs_cubit_test.dart).

## Verify coverage

Before calling a test file done, check it hits 100% on every file it covers — bloc, event, *and* state:

```
fvm flutter test --coverage test/blocs/foo/bar/bar_bloc_test.dart
awk '/^SF:.*bar_bloc\.dart$/{f=1} f{print} f&&/^end_of_record/{exit}' coverage/lcov.info
```

`LH`/`LF` at the bottom are hit/found lines — equal means 100%. For any `DA:<line>,0`, decide whether it's a real gap (add a test) or legitimately unreachable (e.g. the parity exceptions above) — this is a judgment call, not something to hand off to a hook.
