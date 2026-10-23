import 'package:flutter_test/flutter_test.dart';
import 'package:fnb_menu_cart/utils/data_types/price.dart';

void main() {
  group('formatPrice -', () {
    test('formats cents as dollars with two decimals', () {
      expect(formatPrice(797), r'$7.97');
      expect(formatPrice(199), r'$1.99');
    });

    test('always shows two decimal places', () {
      expect(formatPrice(500), r'$5.00');
      expect(formatPrice(50), r'$0.50');
    });

    test('formats zero', () {
      expect(formatPrice(0), r'$0.00');
    });

    test('adds thousands separators', () {
      expect(formatPrice(123456), r'$1,234.56');
    });
  });
}
