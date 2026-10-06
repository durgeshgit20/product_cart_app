import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/wishlist_bloc.dart';
import '../bloc/wishlist_state.dart';

/// The app-bar heart with a badge counting Wishlisted Products, hidden at
/// zero.
class WishlistAppBarButton extends StatelessWidget {
  const WishlistAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistBloc, WishlistState>(
      builder: (context, state) {
        final count = switch (state) {
          WishlistLoading() => 0,
          WishlistLoaded(:final count) => count,
        };
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              key: const Key('wishlist_app_bar_button'),
              tooltip: 'Wishlist',
              icon: const Icon(Icons.favorite),
              // The Wishlist screen arrives in a later ticket.
              onPressed: () {},
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: IgnorePointer(
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$count',
                      semanticsLabel: '$count Wishlisted',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
