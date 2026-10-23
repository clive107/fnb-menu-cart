import 'package:intl/intl.dart';

// DummyJSON prices are in US dollars.
final NumberFormat _priceFormat = NumberFormat.currency(
  decimalDigits: 2,
  locale: 'en_US',
  symbol: r'$',
);

/// Formats an amount in cents for display, e.g. 797 → "$7.97". The only place
/// cents are turned into dollars.
String formatPrice(int priceInCents) => _priceFormat.format(priceInCents / 100);
