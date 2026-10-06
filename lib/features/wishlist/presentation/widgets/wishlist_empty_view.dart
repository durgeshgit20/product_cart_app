import 'package:flutter/material.dart';

/// Shown on the Wishlist screen when nothing is Wishlisted.
class WishlistEmptyView extends StatelessWidget {
  /// Leads back to the catalog.
  final VoidCallback onExplore;

  const WishlistEmptyView({super.key, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          children: [
            Icon(Icons.favorite_border, size: 64, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Your Wishlist is Empty',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the heart on a Product to save it for later.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.storefront_rounded, size: 20),
              label: const Text('Explore Products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
