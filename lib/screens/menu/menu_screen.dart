import 'package:flutter/material.dart';
import 'package:fnb_menu_cart/widgets/order/cart_button.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [CartButton()], title: const Text('Menu')),
      body: const Center(child: Text('Menu')),
    );
  }
}
