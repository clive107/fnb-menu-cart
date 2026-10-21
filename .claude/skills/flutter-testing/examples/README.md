# flutter-testing examples

These files are **reference material** for the conventions in [`../SKILL.md`](../SKILL.md). Each folder
holds a BLoC (or cubit) plus its test, linked from a specific section of `SKILL.md`.

## About these examples

Illustrative code written against a hypothetical app, `package:example_app`, that follows the same
conventions. Their `package:example_app/...` imports and adjacent types (`services/...`, domain models,
`sentry_flutter`) **do not resolve in this repo** — that is expected.
They are documentation, not part of this repo's build; `.claude/**` is excluded from the analyzer (see
`analysis_options.yaml`) so they never surface in `flutter analyze` or the IDE Problems panel.

Do not "fix" the imports or wire these into `lib/` — when a real equivalent is built in this repo, add its
own test under `test/` following `SKILL.md`.

## Contents

| Folder | Referenced by `SKILL.md` for |
|---|---|
| `update_note/` | The **canonical structure** for BLoC event & state coverage — an event that carries data (`UpdateNote`) and a state with **two** status enums (`GetNoteStatus` + `UpdateNoteStatus`), each with its own `StatusX`, plus `copyWith` over several `Optional<T>` fields. |
| `note_details/` | The `_NoOpFooEvent` fixture pattern — every concrete event overrides `props`, so a private no-op subclass is needed to cover the abstract base event's `props => []`. |
| `base_tabs/` | The **Cubits** section — no events / status enum / `copyWith`; assert the emitted state directly, plain `test()`s for the initial state and constructor callbacks, manual `cubit.close()`. |

Each BLoC folder contains the `_bloc.dart` + `part` `_event.dart` + `part` `_state.dart` trio and the
`_bloc_test.dart`. `base_tabs/` is a plain cubit: just `base_tabs_cubit.dart` + `base_tabs_cubit_test.dart`.
