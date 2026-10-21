# Project

Take-home assessment: an F&B menu and cart built with Flutter, Material 3 and Bloc/Cubit, using
DummyJSON as the data source. Targets: Android API 26+ and iOS 16+.

# Dart & Flutter Versions

The minimum supported version is Flutter 3.38.10 (Dart 3.10.9); development uses Flutter 3.47.5
(`.fvmrc`). Don't use Dart language features newer than 3.10 — for example, write
`Foo({required Logger logger}) : _logger = logger`, not `Foo({required this._logger})`.

# Flutter Widget Property Ordering

When writing Flutter widget constructors, always order named properties as follows:

1. **`key`** — always first
2. **All other properties** — alphabetical order
3. **`builder` and `*Builder` properties** (`builder`, `itemBuilder`, `separatorBuilder`, etc.) — alphabetical among themselves, after regular properties
4. **`child` / `children` / `slivers`** — always last

### Example

```dart
ListView.separated(
  padding: const EdgeInsets.all(16.0),
  scrollDirection: Axis.vertical,
  itemBuilder: (context, index) => ...,
  separatorBuilder: (context, index) => ...,
)
```

# Section Comments

Mark each significant block of code with a comment on the line directly above it:
`/* Section - <Name> */`. If the block is the value of a named property (`child:`, `body:`), put the
comment above the property.

- **UI blocks:** name the component or region (`/* Section - Cart summary */`,
  `/* Section - Bottom container */`). Use this for distinct visual regions, not for every widget.
- **Bloc widgets:** always comment `BlocProvider`, `BlocListener`, `BlocSelector`, `BlocBuilder`,
  and `BlocConsumer` as `/* Section - <Widget> for <BlocName> */`.
- **Multi-bloc widgets:** `MultiBlocProvider` and `MultiBlocListener` wrap several blocs, so use the
  widget name alone, without `for <BlocName>`: `/* Section - MultiBlocListener */`.
- **Constant groups:** `/* Section - Constants for padding */`.

```dart
/* Section - BlocSelector for CartCubit */
BlocSelector<CartCubit, CartState, int>(
  selector: (state) => state.quantityOf(itemId),
  builder: (context, quantity) => ...,
)
```

# Variable & Constant Declarations

Always declare an explicit type — never use `var` or bare `final`/`const` with inferred types.

# Theme & Text Styles

- Style text by overriding the `TextTheme` slots and component themes in the app theme, then use
  `Theme.of(context).textTheme.<slot>`. Don't create custom text style classes.
- Never hardcode text or surface colours. Take them from `Theme.of(context).colorScheme` so light
  and dark mode both work.

# BLoC Conventions

## Bloc or Cubit

- API-backed state uses a **Bloc** with events (`MenuItemListBloc`, `CheckoutBloc`).
- Synchronous local state uses a **Cubit** (`CartCubit`).

## Status Enums

There is no authentication, so every status enum uses `initial, loading, success, failure` (no
`tokenExpired`).

Always add a `StatusX` extension with boolean getters immediately after the enum:

```dart
extension FooStatusX on FooStatus {
  bool get isInitial => this == FooStatus.initial;
  bool get isLoading => this == FooStatus.loading;
  bool get isSuccess => this == FooStatus.success;
  bool get isFailure => this == FooStatus.failure;
}
```

## State `copyWith`

For nullable fields in `copyWith`, use `Optional<T>` (not `T?`) so callers can explicitly set a field to `null`:

```dart
// imports needed
import 'package:fnb_menu_cart/models/data_types/optional.dart'; // Optional<T>
import 'package:fnb_menu_cart/utils/data_types/optional.dart';  // resolveOptional()

Optional<Failure> failure = const Optional(),

failure: resolveOptional(failure, this.failure),
```

## Naming — List Operations

When a service method, request DTO, event, status enum, or state field relates to fetching a **list** of objects, always suffix with `List`:

- Service method: `getMenuItemList()`
- Event: `GetMenuItemList`
- Status enum: `GetMenuItemListStatus`
- State fields: `menuItemList`, `getMenuItemListStatus`, `getMenuItemListFailure`

## Events

Name events as verb phrases describing the action (`GetMenuItemList`, `PlaceOrder`), not nouns.

# Dependency Injection

Services are created in `app.dart` and provided with `MultiRepositoryProvider`; blocs and cubits
receive them through constructor parameters. No service locator (`get_it`).

# Tests

When you create a new util, BLoC, or cubit, you must also create a corresponding test file under `test/` mirroring the source path:
- `lib/utils/foo/bar.dart` → `test/utils/foo/bar_test.dart`
- `lib/blocs/foo/bar/bar_bloc.dart` → `test/blocs/foo/bar/bar_bloc_test.dart`
- `lib/blocs/foo/bar/bar_cubit.dart` → `test/blocs/foo/bar/bar_cubit_test.dart`

Model tests are not required for now.

Before writing or reviewing any test, use the `flutter-testing` skill — it holds the detailed conventions (bloc_test/mocktail setup, BLoC event & state coverage, state-assertion rules, error-path parity, and cubits).

# Commits

Commits where Claude helped write the code end with a `Co-Authored-By: Claude` line. Commits the
user wrote alone don't.
