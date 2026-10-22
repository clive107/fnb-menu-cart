import 'package:flutter_test/flutter_test.dart';
import 'package:fnb_menu_cart/utils/data_types/string.dart';

void main() {
  group('toSentenceCase -', () {
    test('capitalises only the first letter', () {
      expect(toSentenceCase('cooking essentials'), 'Cooking essentials');
    });

    test('handles a single character', () {
      expect(toSentenceCase('a'), 'A');
    });

    test('leaves an already capitalised value unchanged', () {
      expect(toSentenceCase('Fruits'), 'Fruits');
    });

    test('returns an empty string unchanged', () {
      expect(toSentenceCase(''), '');
    });
  });
}
