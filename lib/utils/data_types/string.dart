/// Capitalises the first letter, e.g. "cooking essentials" → "Cooking
/// essentials". Used for category names, which arrive as lowercase tags.
String toSentenceCase(String value) {
  if (value.isEmpty) {
    return value;
  }
  return value[0].toUpperCase() + value.substring(1);
}
