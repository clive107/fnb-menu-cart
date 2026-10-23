import 'package:flutter/material.dart';
import 'package:fnb_menu_cart/configs/themes/styles.dart';

/// A square, rounded item photo, with an icon while there's no image or it
/// fails to load.
class MenuItemThumbnail extends StatelessWidget {
  final double size;
  final String? url;

  const MenuItemThumbnail({super.key, required this.size, required this.url});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Widget placeholder = Icon(
      Icons.restaurant,
      color: colorScheme.onSurfaceVariant,
    );
    // Decode at display size rather than full resolution, to save memory.
    final int cacheSize = (size * MediaQuery.devicePixelRatioOf(context))
        .round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadii.thumbnail),
      child: Container(
        color: colorScheme.surfaceContainerHighest,
        height: size,
        width: size,
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                cacheHeight: cacheSize,
                cacheWidth: cacheSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
      ),
    );
  }
}
