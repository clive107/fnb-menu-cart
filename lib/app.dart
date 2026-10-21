import 'package:flutter/material.dart';
import 'package:fnb_menu_cart/screens/cart/cart_screen.dart';
import 'package:fnb_menu_cart/screens/menu/menu_screen.dart';
import 'package:fnb_menu_cart/utils/app/app_routes.dart';

void runMainApp() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.menu,
      routes: {
        /* Section - Menu screen */
        AppRoutes.menu: (context) => const MenuScreen(),
        /* Section - Cart screen */
        AppRoutes.cart: (context) => const CartScreen(),
      },
      title: 'F&B Menu',
    );
  }
}
