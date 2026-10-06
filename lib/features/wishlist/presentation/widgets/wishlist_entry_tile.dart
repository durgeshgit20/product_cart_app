import 'package:flutter/material.dart';

import '../../domain/entities/wishlist_entry.dart';

/// One Wishlist entry: the Product's image, name and price, with its actions.
class WishlistEntryTile extends StatelessWidget {
  final WishlistEntry entry;
  final VoidCallback onRemove;

  const WishlistEntryTile({
    super.key,
    required this.entry,
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
