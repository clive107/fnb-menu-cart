import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnb_menu_cart/configs/themes/app_colors.dart';
import 'package:fnb_menu_cart/configs/themes/styles.dart';
import 'package:fnb_menu_cart/screens/cart/cart_screen.dart';
import 'package:fnb_menu_cart/screens/menu/menu_screen.dart';
import 'package:fnb_menu_cart/services/app/api_client.dart';
import 'package:fnb_menu_cart/utils/app/app_routes.dart';
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
      ],
      child: MaterialApp(
        darkTheme: _buildTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.menu,
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
