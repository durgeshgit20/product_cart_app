import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/badged_icon_button.dart';
import '../bloc/wishlist_bloc.dart';
import '../bloc/wishlist_state.dart';
import '../pages/wishlist_screen.dart';

/// The app-bar heart with a badge counting Wishlisted Products, hidden at
/// zero.
class WishlistAppBarButton extends StatelessWidget {
  const WishlistAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistBloc, WishlistState>(
      buildWhen: (previous, current) => previous.count != current.count,
      builder: (context, state) => BadgedIconButton(
        buttonKey: const Key('wishlist_app_bar_button'),
        tooltip: 'Wishlist',
        icon: const Icon(Icons.favorite),
        count: state.count,
        badgeSemanticsLabel: '${state.count} Wishlisted',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: context.read<WishlistBloc>(),
              child: const WishlistScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
