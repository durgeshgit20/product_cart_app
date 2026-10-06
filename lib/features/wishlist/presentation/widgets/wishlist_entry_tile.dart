import 'package:flutter/material.dart';

import '../../domain/entities/wishlist_entry.dart';

/// One Wishlist entry: the Product's image, name and price, its Price Drop,
/// Out of Stock and No Longer Available labels, and its actions.
class WishlistEntryTile extends StatelessWidget {
  final WishlistEntry entry;
  final bool isNoLongerAvailable;
  final VoidCallback onRemove;

  const WishlistEntryTile({
    super.key,
    required this.entry,
    required this.isNoLongerAvailable,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final product = entry.product;
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
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepPurple,
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
                            color: Colors.green.shade700,
                          ),
                        if (entry.isOutOfStock)
                          _Label(
                            key: Key('wishlist_out_of_stock_${product.id}'),
                            text: 'Out of Stock',
                            color: Colors.redAccent,
                          ),
                        if (isNoLongerAvailable)
                          _Label(
                            key: Key(
                              'wishlist_no_longer_available_${product.id}',
                            ),
                            text: 'No Longer Available',
                            color: Colors.grey.shade700,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            TextButton.icon(
              key: Key('wishlist_remove_${product.id}'),
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Remove'),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small coloured label on a Wishlist entry.
class _Label extends StatelessWidget {
  final String text;
  final Color color;

  const _Label({super.key, required this.text, required this.color});

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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
