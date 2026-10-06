import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/widgets/cart_app_bar_button.dart';
import '../bloc/wishlist_bloc.dart';
import '../bloc/wishlist_event.dart';
import '../bloc/wishlist_state.dart';
import '../widgets/wishlist_empty_view.dart';
import '../widgets/wishlist_entry_tile.dart';

/// Lists the Wishlisted Products, most recently Wishlisted first.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  /// Move to Cart and Remove: the blocs stay independent, so this screen
  /// coordinates them. It acts only on an outcome the Wishlist reports once
  /// the change is saved, so a move or removal that didn't happen never
  /// reaches the Cart or offers Undo.
  void _onOutcome(BuildContext context, WishlistOutcome outcome) {
    switch (outcome) {
      case MovedToCartOutcome(:final entry):
        // Adds one, or increases the quantity if it's already in the Cart.
        context.read<CartBloc>().add(AddToCartEvent(entry.product));
      case RemovedOutcome(:final entry):
        final bloc = context.read<WishlistBloc>();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${entry.product.name} removed from your Wishlist'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => bloc.add(const WishlistRemovalUndone()),
              ),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Wishlist'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: const [CartAppBarButton()],
      ),
      body: BlocConsumer<WishlistBloc, WishlistState>(
        listenWhen: (_, current) =>
            current is WishlistLoaded && current.outcome != null,
        listener: (context, state) {
          if (state case WishlistLoaded(:final outcome?)) {
            _onOutcome(context, outcome);
          }
        },
        builder: (context, state) => switch (state) {
          WishlistLoading() => const Center(child: CircularProgressIndicator()),
          WishlistLoaded(:final entries) when entries.isEmpty =>
            WishlistEmptyView(onExplore: () => Navigator.pop(context)),
          WishlistLoaded(:final entries) => ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return WishlistEntryTile(
                key: ValueKey(entry.productId),
                entry: entry,
                isNoLongerAvailable: state.isNoLongerAvailable(entry.productId),
                canMoveToCart: state.canMoveToCart(entry.productId),
                onMoveToCart: () => context.read<WishlistBloc>().add(
                  WishlistMovedToCart(entry.productId),
                ),
                onRemove: () => context.read<WishlistBloc>().add(
                  WishlistEntryRemoved(entry.productId),
                ),
              );
            },
          ),
        },
      ),
    );
  }
}
