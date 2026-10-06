import 'package:equatable/equatable.dart';
import '../../domain/entities/wishlist_entry.dart';

sealed class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

/// Entries are still being loaded from storage.
final class WishlistLoading extends WishlistState {
  const WishlistLoading();
}

final class WishlistLoaded extends WishlistState {
  /// Most recently Wishlisted first.
  final List<WishlistEntry> entries;

  /// Ids of the Products in the latest catalog published, or null before
  /// any catalog has been published.
  final Set<String>? catalogIds;

  const WishlistLoaded(this.entries, {this.catalogIds});

  int get count => entries.length;

  bool isWishlisted(String productId) =>
      entries.any((entry) => entry.productId == productId);

  /// No Longer Available: the Product is missing from the latest catalog.
  /// Nothing is No Longer Available before the first catalog arrives.
  bool isNoLongerAvailable(String productId) =>
      catalogIds?.contains(productId) == false;

  /// Can Move to Cart: the Product is Wishlisted, and neither Out of Stock
  /// nor No Longer Available.
  bool canMoveToCart(String productId) =>
      !isNoLongerAvailable(productId) &&
      entries.any(
        (entry) => entry.productId == productId && !entry.isOutOfStock,
      );

  WishlistLoaded withEntries(List<WishlistEntry> entries) =>
      WishlistLoaded(entries, catalogIds: catalogIds);

  @override
  List<Object?> get props => [entries, catalogIds];
}
