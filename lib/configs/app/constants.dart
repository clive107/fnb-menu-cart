/* Section - API */
const String kApiBaseUrl = 'https://dummyjson.com';
const Duration kApiTimeout = Duration(seconds: 15);

/* Section - Menu */
// DummyJSON has no menu, so its groceries category stands in for one.
const String kMenuCategoryPath = 'products/category/groceries';
// First tags of grocery items that aren't food or drink, left off the menu.
const Set<String> kNonFoodTags = {
  'health supplements',
  'household essentials',
  'pet supplies',
};
// No grocery item is out of stock in DummyJSON, so these are forced out of
// stock to show that state (Fish Steak, Nescafe Coffee).
const Set<int> kDemoOutOfStockItemIds = {24, 34};

/* Section - Checkout */
const String kPlaceOrderPath = 'carts/add';
// DummyJSON's carts/add requires a user; this app has no accounts.
const int kDemoUserId = 1;
// Build with --dart-define=FORCE_CHECKOUT_FAILURE=true to make every order
// fail, so the checkout error state can be shown.
const bool kForceCheckoutFailure = bool.fromEnvironment(
  'FORCE_CHECKOUT_FAILURE',
);
