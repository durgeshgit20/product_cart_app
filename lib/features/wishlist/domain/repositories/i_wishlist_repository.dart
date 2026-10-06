import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/wishlist_entry.dart';

/// Stores the Wishlist for the current Data Source.
///
/// It only stores: the rules live in `WishlistBloc`.
abstract interface class IWishlistRepository {
  /// Loads every saved entry. Unreadable or corrupt data loads as empty.
  EitherResponse<List<WishlistEntry>> loadEntries();

  /// Replaces the saved entries with [entries].
  EitherResponse<Unit> saveEntries(List<WishlistEntry> entries);
}
