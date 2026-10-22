# F&B Menu & Cart

A slice of a food-ordering app: a menu grouped by category, a cart, and a checkout action. Built
with Flutter, Material 3 and Bloc/Cubit.

| Menu | Cart |
|---|---|
| Items grouped under sticky category headers, with name, description, price and availability. Out-of-stock items are faded and can't be added. Add turns into an inline quantity stepper. | Quantity controls and remove, a running total, and Place Order with in-flight, success and error states. |

## Setup

**Requirements:** Flutter 3.38.10 or later (Dart 3.10+). Developed on Flutter 3.47.5, pinned in
`.fvmrc` for [FVM](https://fvm.app) users. Android API 26+ and iOS 16+.

```bash
flutter pub get
flutter run                 # or: fvm flutter run
flutter test                # 107 unit and widget tests
```

To demo the checkout error state, make every order fail:

```bash
flutter run --dart-define=FORCE_CHECKOUT_FAILURE=true
```

VS Code users can pick the matching configuration in `.vscode/launch.json`.

## Data source: DummyJSON

No API key or setup is needed.

- **Menu:** `GET https://dummyjson.com/products/category/groceries?limit=0`. DummyJSON has no menu
  or menu categories, so each product's first tag becomes its category (Fruits, Meat, Beverages…),
  and non-food items (pet supplies, household essentials, supplements) are dropped.
- **Availability:** from `stock` and `availabilityStatus`. No grocery item is out of stock in
  DummyJSON, so two items (Fish Steak, Nescafe Coffee) are forced out of stock to show that state.
  The IDs are in `kDemoOutOfStockItemIds` (`lib/configs/app/constants.dart`).
- **Checkout:** `POST https://dummyjson.com/carts/add` with the cart's item IDs and quantities.
  It returns an order ID but doesn't save anything.
- **Money** is kept as integer cents in the app, and shown in US dollars as DummyJSON returns it.
  DummyJSON's own cart total for a $7.97 order came back as `7.970000000000001`.

## Architecture

The structure is layer-first, following the conventions of my existing production Flutter apps
(the conventions are in `CLAUDE.md`).

```
lib/
├── main.dart          # Calls runMainApp()
├── app.dart           # Creates services, provides them and the blocs above MaterialApp, theme, routes
├── screens/           # One widget per route (menu, cart)
├── widgets/           # Reusable UI pieces, grouped by feature (menu/, order/, common/)
├── blocs/             # State management: MenuItemListBloc, CartCubit, CheckoutBloc (each with its state/events)
├── services/          # API calls: ApiClient (HTTP, timeout, errors → Failure), MenuService, OrderService
├── models/            # Immutable data classes: MenuItem, MenuSection, CartItem, Failure, Optional
├── enums/             # MenuItemAvailability
├── configs/           # Constants (API paths, demo IDs) and theme tokens
└── utils/             # Small pure helpers: price formatting, failure messages, navigator key
```

**Dependencies** flow one way: `screens/widgets → blocs → services → ApiClient`, with `models`
shared by all layers. Widgets never call services; services never know about blocs or widgets.
Services return the API's JSON, and blocs turn it into models.

**How dependencies are provided:** constructor injection, wired up with `flutter_bloc`'s providers.
`runMainApp()` creates the `Logger` and `ApiClient`. `MyApp` provides the services with
`MultiRepositoryProvider`, then the blocs with `MultiBlocProvider`. Both sit **above
`MaterialApp`**, so the menu, the cart and an order in flight survive navigation, rotation, theme
changes and resizing. Each bloc receives its services through its constructor: `app.dart` passes
the real ones with `context.read<MenuService>()`, and tests pass in mocks, with no service
locator needed.

**State management: Bloc/Cubit.** API-driven state (menu, checkout) uses a Bloc with explicit
events, which keeps the async flows easy to trace and test with `bloc_test`. The cart is
synchronous, so it's a simpler Cubit. `BlocSelector` keeps rebuilds small (see design question 1).

**Navigation: `Navigator` with named routes.** Two screens and no deep links, so the built-in
navigator is the simplest thing that works.

### Extending it: promo codes

The user enters a code in the cart, an API validates it, and the total shows a discount.

**Add:**
- `services/order/promo_service.dart`: `validatePromoCode(code, cartTotalInCents)`, calling e.g.
  `POST /promos/validate`.
- `models/order/promo.dart`: the code, discount type (percentage or fixed amount in cents),
  minimum spend, and a display label.
- `blocs/order/promo/promo_bloc.dart`: events `ApplyPromoCode` and `RemovePromoCode`. State holds
  the validation status and failure ("code expired"), plus the applied `Promo`. It's provided above
  `MaterialApp` like the others.
- `utils/order/calculate_order_total.dart`: a pure function `(subtotalInCents, promo) →
  (discountInCents, totalInCents)`, unit-tested for rounding and minimum spend.
- `widgets/order/promo_code_field.dart`: a text field with an Apply button, or the applied code
  with a remove button.

**Change:**
- `cart_screen.dart`: add the promo field, and show subtotal, discount and total in the summary.
- `PlaceOrderRequest`: include the promo code, so the server applies and checks it again. The
  server's total is the one that counts.
- The promo is re-validated when the cart total changes, since a minimum spend may no longer be
  met.

**Leave untouched:** `CartCubit` (the cart is *what* you're buying; a promo only changes the
price, so it gets its own bloc), the menu screen and `MenuItemListBloc`, `ApiClient`, and the
theme.

## Design questions

**1. State shape.**
- Three separate pieces of state: `MenuItemListBloc` (the items with their loading and error
  status, since one fetch decides all of them), `CartCubit` (a map of item ID to `CartItem`, with
  totals derived) and `CheckoutBloc`.
- Items are grouped into sections once per fetch, not on every build.
- A "+" tap only changes `CartCubit`, so only two widgets rebuild, each through a `BlocSelector`:
  that card's quantity control (`quantityOf(id)`) and the cart badge (`totalQuantity`).
- A widget test checks that the list and the other cards don't rebuild.

**2. API contract.**
- An **idempotency key** for placing orders: the app sends a unique ID with each checkout attempt,
  and the server treats repeats as the same order.
- Today, if a request times out after the server has saved the order, a retry places a second one.
- `CheckoutBloc` would create the key on Place Order, reuse it when retrying the same cart, and
  clear it after success or when the cart changes.
- Runner-up: prices as integer cents, so the app doesn't have to convert floats.

**3. Async edge cases.**
- Leaving the cart doesn't cancel the order: `CheckoutBloc` and `CartCubit` are provided above
  `MaterialApp`.
- App-level listeners show the result on whichever screen is open. Success clears the cart and
  shows a dialog; failure keeps the cart and shows a snackbar.
- Cart controls are locked on both screens while the order is in flight, so the cart that gets
  cleared is exactly what was ordered.
- Backgrounded: the order state survives, and the result shows when the user comes back. Killed
  by the OS: the result is lost, as state is in memory only.
- Double submission is blocked twice: the button is disabled, and `CheckoutBloc` ignores
  `PlaceOrder` while loading. It emits `loading` before its first `await`, so even two taps in the
  same frame are caught (tested).

**4. With two more hours.**
- CI (GitHub Actions) running `flutter analyze` and `flutter test` on Flutter 3.38.10 (the
  minimum) and the latest stable.
    - Some widget tests already broke on 3.38 only: `FilledButton.tonalIcon` builds a private
      subclass there, so the finder missed the Add button. I found it by running the tests on
      3.38 by hand.

**5. Scaling to 2,000 items in 40 categories.**
- The list already builds items lazily, and thumbnails are decoded at display size, so rendering
  is fine.
- What slows down first is loading: the app fetches the whole menu in one request (`limit=0`).
- I'd use pagination: load the first page (e.g. 20 items), then the next page when the user
  scrolls near the end.
- With 40 categories, scrolling to find one is slow, so I'd add a category picker that jumps to
  each section.

## Testing

107 tests, all passing on Flutter 3.38.10 and 3.47.5:

- **Blocs and cubit** (`bloc_test` + `mocktail`): every event, state, `copyWith` path and error
  branch, at 100% line coverage. This includes the double-submit guard, with a second tap arriving
  while the first request is still pending.
- **Utils:** price formatting, failure messages, `Optional`.
- **Widget tests:** the menu (grouping, out-of-stock, stock limit, retry, sticky headers, which
  widgets rebuild on "+", no overflow at 320px). The cart tests run the real app with only
  `ApiClient` mocked: totals, controls, empty state, the full order flow, failure, and leaving the
  cart mid-order (success and failure).

## AI usage

I built this with Claude Code as a pair programmer.

- **Setup:** I gave it a `CLAUDE.md` and a `flutter-testing` skill (`.claude/skills/`) adapted from
  my existing projects, so the code and tests follow my usual conventions.
- **Decisions:** mine, including the architecture, Bloc, and the navigation approach.
- **Drafts and review:** the AI wrote first drafts of code and tests. I reviewed every commit and
  caught issues it had missed. For example, I noticed an item could be added beyond its stock
  limit, so I asked the AI to fix it. I also found tests that checked several cases at once,
  which made them confusing, so I asked for them to be split and grouped properly, with clearer
  names and finders.
- **Commits** written with AI help carry a `Co-Authored-By` line.
