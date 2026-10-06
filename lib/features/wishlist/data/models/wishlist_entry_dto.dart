import '../../../products/domain/entities/product.dart';
import '../../domain/entities/wishlist_entry.dart';

/// JSON form of a [WishlistEntry] as kept on the device.
///
/// [fromJson] throws a [FormatException] or [TypeError] on malformed data.
class WishlistEntryDto {
  final WishlistEntry entry;

  const WishlistEntryDto(this.entry);

  factory WishlistEntryDto.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>;
    return WishlistEntryDto(
      WishlistEntry(
        product: Product(
          id: product['id'] as String,
          name: product['name'] as String,
          description: product['description'] as String,
          price: (product['price'] as num).toDouble(),
          imageUrl: product['imageUrl'] as String,
          stockQuantity: product['stockQuantity'] as int,
          isOutOfStock: product['isOutOfStock'] as bool,
        ),
        wishlistedPrice: (json['wishlistedPrice'] as num).toDouble(),
        wishlistedAt: DateTime.parse(json['wishlistedAt'] as String),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final product = entry.product;
    return {
      'product': {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'stockQuantity': product.stockQuantity,
        'isOutOfStock': product.isOutOfStock,
      },
      'wishlistedPrice': entry.wishlistedPrice,
      'wishlistedAt': entry.wishlistedAt.toIso8601String(),
    };
  }
}
