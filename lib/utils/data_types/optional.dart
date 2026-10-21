import 'package:fnb_menu_cart/models/data_types/optional.dart';

/// If [optional] is set to [true], return its value; otherwise, return [currentDefault].
/// This is useful when you want to use the existing value if [optional] is not set,
/// and also allow for [null] value when [optional] is set.
T? resolveOptional<T>(Optional<T> optional, T? currentDefault) {
  return optional.isSet ? optional.value : currentDefault;
}
