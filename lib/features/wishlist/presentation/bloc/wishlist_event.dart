import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';

sealed class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the saved Wishlist. Added by the bloc itself when it is created.
final class WishlistStarted extends WishlistEvent {
  const WishlistStarted();
}

/// Wishlists [product], or takes it off the Wishlist if it is Wishlisted.
final class WishlistToggled extends WishlistEvent {
  final Product product;

  const WishlistToggled(this.product);

  @override
  List<Object?> get props => [product];
}
