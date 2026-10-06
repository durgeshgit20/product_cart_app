import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/i_product_repository.dart';
import '../../domain/repositories/i_wishlist_repository.dart';

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

/// Takes the entry for [productId] off the Wishlist from the Wishlist screen,
/// keeping it so that [WishlistRemovalUndone] can put it back.
final class WishlistEntryRemoved extends WishlistEvent {
  final String productId;

  const WishlistEntryRemoved(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Puts back the entry most recently taken off by [WishlistEntryRemoved],
/// with its original Price Drop baseline and Wishlisted time.
final class WishlistRemovalUndone extends WishlistEvent {
  const WishlistRemovalUndone();
}

/// The Data Source was switched: shows [wishlistRepository]'s Wishlist and
/// follows [productRepository]'s catalog from now on.
final class WishlistRepositoriesSwitched extends WishlistEvent {
  final IWishlistRepository wishlistRepository;
  final IProductRepository productRepository;

  const WishlistRepositoriesSwitched({
    required this.wishlistRepository,
    required this.productRepository,
  });

  @override
  List<Object?> get props => [wishlistRepository, productRepository];
}
