import 'package:flutter_test/flutter_test.dart';
import 'package:fnb_menu_cart/models/data_types/optional.dart';
import 'package:fnb_menu_cart/utils/data_types/optional.dart';

void main() {
  group('resolveOptional -', () {
    test('returns currentDefault when the optional is not set', () {
      const Optional<String> optional = Optional<String>();

      expect(resolveOptional<String>(optional, 'default'), 'default');
      expect(resolveOptional<String>(optional, null), isNull);
    });

    test('returns the set value when the optional holds a non-null value', () {
      const Optional<String> optional = Optional<String>.set('value');

      expect(resolveOptional<String>(optional, 'default'), 'value');
    });

    test('returns null when the optional is explicitly set to null', () {
      const Optional<String> optional = Optional<String>.set(null);

      expect(resolveOptional<String>(optional, 'default'), isNull);
    });

    test('works with non-String type arguments', () {
      expect(resolveOptional<int>(const Optional<int>.set(7), 3), 7);
      expect(resolveOptional<int>(const Optional<int>(), 3), 3);
    });
  });
}
