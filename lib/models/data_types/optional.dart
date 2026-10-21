/// This model enables us to distinguish between two scenarios: when no value is passed to an optional parameter and when a null value is passed,
/// allowing us to handle each scenario differently.
class Optional<T> {
  final T? value;
  final bool isSet;

  const Optional.set(this.value) : isSet = true;
  const Optional() : value = null, isSet = false;
}
