import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnb_menu_cart/blocs/menu/menu_item_list/menu_item_list_bloc.dart';
import 'package:fnb_menu_cart/blocs/order/cart/cart_cubit.dart';
import 'package:fnb_menu_cart/blocs/order/checkout/checkout_bloc.dart';
import 'package:fnb_menu_cart/configs/themes/app_colors.dart';
import 'package:fnb_menu_cart/configs/themes/styles.dart';
import 'package:fnb_menu_cart/screens/cart/cart_screen.dart';
import 'package:fnb_menu_cart/screens/menu/menu_screen.dart';
import 'package:fnb_menu_cart/services/app/api_client.dart';
import 'package:fnb_menu_cart/services/menu/menu_service.dart';
import 'package:fnb_menu_cart/services/order/order_service.dart';
import 'package:fnb_menu_cart/utils/app/app_routes.dart';
import 'package:fnb_menu_cart/utils/app/global_navigator.dart';
import 'package:fnb_menu_cart/widgets/order/order_placed_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

void runMainApp() {
  final Logger logger = Logger();
  // One client for the app's lifetime, so connections are reused.
  final ApiClient apiClient = ApiClient(
    httpClient: http.Client(),
    logger: logger,
  );

  runApp(MyApp(apiClient: apiClient, logger: logger));
}

class MyApp extends StatelessWidget {
  final ApiClient apiClient;
  final Logger logger;

  const MyApp({super.key, required this.apiClient, required this.logger});

  @override
  Widget build(BuildContext context) {
    /* Section - MultiRepositoryProvider */
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<Logger>.value(value: logger),
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<MenuService>(
          create: (context) => MenuService(apiClient: apiClient),
        ),
        RepositoryProvider<OrderService>(
          create: (context) => OrderService(apiClient: apiClient),
        ),
      ],
      /* Section - MultiBlocProvider */
      // Above MaterialApp, so the menu, cart and an order in flight survive
      // navigation, rotation and theme changes.
      child: MultiBlocProvider(
        providers: [
          BlocProvider<MenuItemListBloc>(
            create: (context) => MenuItemListBloc(
              logger: context.read<Logger>(),
              menuService: context.read<MenuService>(),
            )..add(const GetMenuItemList()),
          ),
          BlocProvider<CartCubit>(
            create: (context) => CartCubit(logger: context.read<Logger>()),
          ),
          BlocProvider<CheckoutBloc>(
            create: (context) => CheckoutBloc(
              logger: context.read<Logger>(),
              orderService: context.read<OrderService>(),
            ),
          ),
        ],
        /* Section - BlocListener for CheckoutBloc */
        // When an order succeeds: clears the cart and confirms with a dialog.
        // It sits here rather than on the cart screen so it still runs if the
        // user has left that screen before the response arrives.
        child: BlocListener<CheckoutBloc, CheckoutState>(
          listenWhen: (previous, current) =>
              previous.placeOrderStatus != current.placeOrderStatus &&
              current.placeOrderStatus.isSuccess,
          listener: (context, state) async {
            context.read<CartCubit>().clearCart();
            // This context is above MaterialApp, so the dialog goes through
            // the navigator key and appears on whichever screen is open.
            final BuildContext? navigatorContext =
                globalNavigatorKey.currentContext;
            if (navigatorContext == null) {
              return;
            }
            final CheckoutBloc checkoutBloc = context.read<CheckoutBloc>();
            await showOrderPlacedDialog(
              context: navigatorContext,
              orderId: state.orderId,
            );
            // Back to the menu, and checkout back to idle for the next order.
            globalNavigatorKey.currentState?.popUntil(
              (Route<dynamic> route) => route.isFirst,
            );
            checkoutBloc.add(const ResetCheckout());
          },
          child: MaterialApp(
            darkTheme: _buildTheme(Brightness.dark),
            debugShowCheckedModeBanner: false,
            initialRoute: AppRoutes.menu,
            navigatorKey: globalNavigatorKey,
            routes: {
              /* Section - Menu screen */
              AppRoutes.menu: (context) => const MenuScreen(),
              /* Section - Cart screen */
              AppRoutes.cart: (context) => const CartScreen(),
            },
            theme: _buildTheme(Brightness.light),
            // Follows the device setting, so switching dark mode on the device
            // switches the app's theme.
            themeMode: ThemeMode.system,
            title: 'F&B Menu',
          ),
        ),
      ),
    );
  }
}

/// Light and dark themes from a single seed colour. Text uses the platform's
/// system font.
ThemeData _buildTheme(Brightness brightness) {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    brightness: brightness,
    seedColor: AppColors.seed,
  );

  return ThemeData(
    appBarTheme: const AppBarTheme(centerTitle: false),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadii.card),
      ),
    ),
    colorScheme: colorScheme,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64.0, AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadii.button),
        ),
      ),
    ),
    // ThemeData merges these with its default typography for [brightness],
    // which supplies the text colours, so none are set here.
    textTheme: _buildTextTheme(),
    useMaterial3: true,
  );
}

/// The `TextTheme` slots the app uses. Sizes and weights only.
TextTheme _buildTextTheme() {
  return const TextTheme(
    /* Section - Titles */
    // App bar title.
    titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
    // Category header.
    titleMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
    // Item name.
    titleSmall: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),

    /* Section - Body */
    // Item description.
    bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400),
    // Secondary details, such as availability.
    bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400),

    /* Section - Labels */
    // Buttons.
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
  );
}
