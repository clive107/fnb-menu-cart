import 'package:equatable/equatable.dart';
import 'package:fnb_menu_cart/enums/menu/menu_item_availability.dart';

class MenuItem extends Equatable {
  final int id;
  final String name;
  final String description;
  // Money is kept in integer cents so totals don't pick up floating-point
  // errors (e.g. 0.1 + 0.2).
  final int priceInCents;
  final String category;
  final MenuItemAvailability availability;
  // Units available; the cart can't hold more than this.
  final int stock;
  final String? thumbnailUrl;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.priceInCents,
    required this.category,
    required this.availability,
    required this.stock,
    this.thumbnailUrl,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    priceInCents,
    category,
    availability,
    stock,
    thumbnailUrl,
  ];

  /// Parses a DummyJSON product. Its first tag becomes the menu category,
  /// since the API has no menu-category field.
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> tags = json['tags'] as List<dynamic>? ?? const [];
    final int stock = json['stock'] as int? ?? 0;
    return MenuItem(
      id: json['id'] as int,
      name: json['title'] as String,
      description: json['description'] as String? ?? '',
      priceInCents: ((json['price'] as num) * 100).round(),
      category: tags.isNotEmpty ? tags.first as String : 'other',
      availability: _parseAvailability(
        stock: stock,
        status: json['availabilityStatus'] as String?,
      ),
      stock: stock,
      thumbnailUrl: json['thumbnail'] as String?,
    );
  }

  static MenuItemAvailability _parseAvailability({
    required int stock,
    String? status,
  }) {
    if (stock <= 0 || status == 'Out of Stock') {
      return MenuItemAvailability.outOfStock;
    }
    if (status == 'Low Stock') {
      return MenuItemAvailability.lowStock;
    }
    return MenuItemAvailability.inStock;
  }
}
