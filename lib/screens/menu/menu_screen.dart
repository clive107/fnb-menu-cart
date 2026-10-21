import 'package:flutter/material.dart';
import 'package:fnb_menu_cart/utils/app/app_routes.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            tooltip: 'Cart',
          ),
        ],
        title: const Text('Menu'),
      ),
      body: const Center(child: Text('Menu')),
    );
  }
}
