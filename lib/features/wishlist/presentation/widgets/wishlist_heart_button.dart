import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../products/domain/entities/product.dart';
import '../bloc/wishlist_bloc.dart';
import '../bloc/wishlist_event.dart';
import '../bloc/wishlist_state.dart';

/// The heart on a product tile: filled when [product] is Wishlisted.
class WishlistHeartButton extends StatelessWidget {
  final Product product;

  const WishlistHeartButton({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistBloc, WishlistState>(
      buildWhen: (previous, current) =>
          previous.isWishlisted(product.id) != current.isWishlisted(product.id),
      builder: (context, state) {
        final isWishlisted = state.isWishlisted(product.id);
        return IconButton(
          key: Key('wishlist_toggle_${product.id}'),
          tooltip: isWishlisted ? 'Remove from Wishlist' : 'Add to Wishlist',
          icon: Icon(
            isWishlisted ? Icons.favorite : Icons.favorite_border,
            color: isWishlisted ? Colors.redAccent : Colors.grey.shade600,
          ),
          onPressed: () =>
              context.read<WishlistBloc>().add(WishlistToggled(product)),
        );
      },
    );
  }
}
