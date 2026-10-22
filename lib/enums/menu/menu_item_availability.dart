enum MenuItemAvailability { inStock, lowStock, outOfStock }

extension MenuItemAvailabilityX on MenuItemAvailability {
  bool get isInStock => this == MenuItemAvailability.inStock;
  bool get isLowStock => this == MenuItemAvailability.lowStock;
  bool get isOutOfStock => this == MenuItemAvailability.outOfStock;
}
