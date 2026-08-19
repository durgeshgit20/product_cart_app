import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;
  final double priceAtAddition;
  final bool hasPriceChanged;
  final double? previousPrice;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.priceAtAddition,
    this.hasPriceChanged = false,
    this.previousPrice,
  });

  double get itemTotal => product.price * quantity;
  bool get isOutOfStock => product.isOutOfStock || product.stockQuantity < quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? priceAtAddition,
    bool? hasPriceChanged,
    double? previousPrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      priceAtAddition: priceAtAddition ?? this.priceAtAddition,
      hasPriceChanged: hasPriceChanged ?? this.hasPriceChanged,
      previousPrice: previousPrice ?? this.previousPrice,
    );
  }

  @override
  List<Object?> get props => [
        product,
        quantity,
        priceAtAddition,
        hasPriceChanged,
        previousPrice,
      ];
}
