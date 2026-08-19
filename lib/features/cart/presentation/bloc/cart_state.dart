import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final String? notificationMessage;

  const CartState({
    this.items = const [],
    this.notificationMessage,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.itemTotal);
  double get tax => subtotal * 0.08; // 8% tax rate
  double get grandTotal => subtotal + tax;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get hasOutOfStockItem => items.any((item) => item.isOutOfStock);

  CartState copyWith({
    List<CartItem>? items,
    String? notificationMessage,
    bool clearNotification = false,
  }) {
    return CartState(
      items: items ?? this.items,
      notificationMessage: clearNotification ? null : (notificationMessage ?? this.notificationMessage),
    );
  }

  @override
  List<Object?> get props => [items, notificationMessage];
}
