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

  const WishlistLoaded(this.entries);

  int get count => entries.length;

  bool isWishlisted(String productId) =>
      entries.any((entry) => entry.productId == productId);

  @override
  List<Object?> get props => [entries];
}
