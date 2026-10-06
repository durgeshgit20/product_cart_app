import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';

/// One Wishlisted Product.
class WishlistEntry extends Equatable {
  /// The saved product details (the latest ones known).
  final Product product;

  /// The price when the Product was Wishlisted: the Price Drop baseline.
  /// It never changes once saved.
  final double wishlistedPrice;

  /// When the Product was Wishlisted, used for newest-first ordering.
  final DateTime wishlistedAt;

  const WishlistEntry({
    required this.product,
    required this.wishlistedPrice,
    required this.wishlistedAt,
  });

  String get productId => product.id;

  /// Price Drop: the current price is strictly lower than the baseline.
  bool get hasPriceDrop => product.price < wishlistedPrice;

  /// Out of Stock, going by the latest known product details.
  bool get isOutOfStock => product.isOutOfStock;

  /// This entry with the latest known [product] details. The baseline and
  /// the Wishlisted time stay as they were.
  WishlistEntry withDetails(Product product) => WishlistEntry(
    product: product,
    wishlistedPrice: wishlistedPrice,
    wishlistedAt: wishlistedAt,
  );

  @override
  List<Object?> get props => [product, wishlistedPrice, wishlistedAt];
}
