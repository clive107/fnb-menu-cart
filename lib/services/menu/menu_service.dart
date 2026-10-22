import 'package:fnb_menu_cart/configs/app/constants.dart';
import 'package:fnb_menu_cart/services/app/api_client.dart';

class MenuService {
  final ApiClient _apiClient;

  MenuService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Returns the API response with `products` limited to food and drink.
  Future<Map<String, dynamic>> getMenuItemList() async {
    final Map<String, dynamic> response = await _apiClient.jsonGet(
      kMenuCategoryPath,
      query: {
        // 0 returns every item in the category.
        'limit': '0',
        'select':
            'title,description,price,stock,availabilityStatus,tags,thumbnail',
      },
    );
    final List<dynamic> products =
        response['products'] as List<dynamic>? ?? const [];
    return {...response, 'products': products.where(_isFood).toList()};
  }

  bool _isFood(dynamic product) {
    final List<dynamic> tags =
        (product as Map<String, dynamic>)['tags'] as List<dynamic>? ?? const [];
    return tags.isEmpty || !kNonFoodTags.contains(tags.first);
  }
}
