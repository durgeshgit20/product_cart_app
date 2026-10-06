import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/badged_icon_button.dart';
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
      buildWhen: (previous, current) => previous.itemCount != current.itemCount,
      builder: (context, cartState) => BadgedIconButton(
        tooltip: 'Cart',
        icon: const Icon(Icons.shopping_cart),
        count: cartState.itemCount,
        badgeSemanticsLabel: '${cartState.itemCount} in Cart',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: context.read<CartBloc>(),
              child: const CartScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
