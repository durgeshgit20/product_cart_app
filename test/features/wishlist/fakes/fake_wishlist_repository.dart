import 'package:fpdart/fpdart.dart';
import 'package:product_cart_app/core/error/failure.dart';
import 'package:product_cart_app/features/wishlist/domain/entities/wishlist_entry.dart';
import 'package:product_cart_app/features/wishlist/domain/repositories/i_wishlist_repository.dart';

/// In-memory [IWishlistRepository]. [saved] is what is on the "device".
class FakeWishlistRepository implements IWishlistRepository {
  List<WishlistEntry> saved;

  /// When set, every load and save fails with this.
  Failure? failWith;

  FakeWishlistRepository([List<WishlistEntry> saved = const []])
    : saved = List.of(saved);

  @override
  EitherResponse<List<WishlistEntry>> loadEntries() => TaskEither(() async {
    final failure = failWith;
    return failure != null ? left(failure) : right(List.of(saved));
  });

  @override
  EitherResponse<Unit> saveEntries(List<WishlistEntry> entries) =>
      TaskEither(() async {
        final failure = failWith;
        if (failure != null) return left(failure);
        saved = List.of(entries);
        return right(unit);
      });
}
