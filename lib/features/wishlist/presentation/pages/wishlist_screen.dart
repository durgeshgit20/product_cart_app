import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/wishlist_bloc.dart';
import '../bloc/wishlist_event.dart';
import '../bloc/wishlist_state.dart';
import '../widgets/wishlist_empty_view.dart';
import '../widgets/wishlist_entry_tile.dart';

/// Lists the Wishlisted Products, most recently Wishlisted first.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  void _remove(BuildContext context, String productId, String name) {
    final bloc = context.read<WishlistBloc>()
      ..add(WishlistEntryRemoved(productId));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$name removed from your Wishlist'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => bloc.add(const WishlistRemovalUndone()),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Wishlist'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<WishlistBloc, WishlistState>(
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
                onRemove: () =>
                    _remove(context, entry.productId, entry.product.name),
              );
            },
          ),
        },
      ),
    );
  }
}
