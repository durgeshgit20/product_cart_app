import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cart_bloc.dart';
import '../bloc/cart_state.dart';
import '../pages/cart_screen.dart';

/// The app-bar cart with a badge counting the items in the Cart, hidden at
/// zero.
class CartAppBarButton extends StatelessWidget {
  const CartAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Cart',
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider.value(
                      value: context.read<CartBloc>(),
                      child: const CartScreen(),
                    ),
                  ),
                );
              },
            ),
            if (cartState.itemCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: IgnorePointer(
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${cartState.itemCount}',
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
