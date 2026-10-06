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

  /// What the event that produced this state did, for the screen to act on
  /// once: null unless this state came from a Move to Cart or a Remove that
  /// was saved.
  final WishlistOutcome? outcome;

  const WishlistLoaded(this.entries, {this.catalogIds, this.outcome});

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

  /// These [entries] with the same catalog, and no [outcome].
  WishlistLoaded withEntries(
    List<WishlistEntry> entries, {
    WishlistOutcome? outcome,
  }) => WishlistLoaded(entries, catalogIds: catalogIds, outcome: outcome);

  @override
  List<Object?> get props => [entries, catalogIds, outcome];
}

/// A change to the Wishlist the screen reacts to once it has been saved.
sealed class WishlistOutcome extends Equatable {
  /// The entry that was taken off the Wishlist.
  final WishlistEntry entry;

  const WishlistOutcome(this.entry);

  @override
  List<Object?> get props => [entry];
}

/// [entry] was Moved to Cart: the screen adds its Product to the Cart.
final class MovedToCartOutcome extends WishlistOutcome {
  const MovedToCartOutcome(super.entry);
}

/// [entry] was removed: the screen offers Undo.
final class RemovedOutcome extends WishlistOutcome {
  const RemovedOutcome(super.entry);
}
