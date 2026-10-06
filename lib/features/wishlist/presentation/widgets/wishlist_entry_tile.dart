import 'package:flutter/material.dart';

import '../../domain/entities/wishlist_entry.dart';

/// One Wishlist entry: the Product's image, name and price, its Price Drop,
/// Out of Stock and No Longer Available labels, and its actions.
class WishlistEntryTile extends StatelessWidget {
  final WishlistEntry entry;
  final bool isNoLongerAvailable;

  /// Whether Move to Cart is enabled for this entry.
  final bool canMoveToCart;
  final VoidCallback onMoveToCart;
  final VoidCallback onRemove;

  const WishlistEntryTile({
    super.key,
    required this.entry,
    required this.isNoLongerAvailable,
    required this.canMoveToCart,
    required this.onMoveToCart,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final product = entry.product;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 70,
                  height: 70,
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (entry.hasPriceDrop ||
                      entry.isOutOfStock ||
                      isNoLongerAvailable) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (entry.hasPriceDrop)
                          _Label(
                            key: Key('wishlist_price_drop_${product.id}'),
                            text:
                                'Price Drop · was '
                                '\$${entry.wishlistedPrice.toStringAsFixed(2)}',
                            color: colorScheme.tertiary,
                            onColor: colorScheme.onTertiary,
                          ),
                        if (entry.isOutOfStock)
                          _Label(
                            key: Key('wishlist_out_of_stock_${product.id}'),
                            text: 'Out of Stock',
                            color: colorScheme.error,
                            onColor: colorScheme.onError,
                          ),
                        if (isNoLongerAvailable)
                          _Label(
                            key: Key(
                              'wishlist_no_longer_available_${product.id}',
                            ),
                            text: 'No Longer Available',
                            color: colorScheme.onSurfaceVariant,
                            onColor: colorScheme.surface,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  key: Key('wishlist_move_to_cart_${product.id}'),
                  // Null disables the button: Out of Stock or No Longer
                  // Available.
                  onPressed: canMoveToCart ? onMoveToCart : null,
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Move to Cart'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                TextButton.icon(
                  key: Key('wishlist_remove_${product.id}'),
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A small coloured label on a Wishlist entry: [onColor] text on [color].
class _Label extends StatelessWidget {
  final String text;
  final Color color;
  final Color onColor;

  const _Label({
    super.key,
    required this.text,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          text,
          style: TextStyle(
            color: onColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
