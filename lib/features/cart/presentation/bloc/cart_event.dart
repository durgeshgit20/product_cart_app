import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCartEvent extends CartEvent {
  final Product product;

  const AddToCartEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class RemoveFromCartEvent extends CartEvent {
  final String productId;

  const RemoveFromCartEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class UpdateQuantityEvent extends CartEvent {
  final String productId;
  final int newQuantity;

  const UpdateQuantityEvent({
    required this.productId,
    required this.newQuantity,
  });

  @override
  List<Object?> get props => [productId, newQuantity];
}

class SyncCartWithProductsEvent extends CartEvent {
  final List<Product> updatedProducts;

  const SyncCartWithProductsEvent(this.updatedProducts);

  @override
  List<Object?> get props => [updatedProducts];
}
