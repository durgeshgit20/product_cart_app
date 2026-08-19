import 'package:flutter/material.dart';
import '../../domain/entities/cart_item.dart';
import 'cart_item_tile.dart';

class CartItemList extends StatelessWidget {
  final List<CartItem> items;
  final Function(CartItem item, int newQty) onQuantityChanged;
  final ValueChanged<String> onRemoveItem;

  const CartItemList({
    super.key,
    required this.items,
    required this.onQuantityChanged,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return CartItemTile(
          item: item,
          onQuantityChanged: (newQty) => onQuantityChanged(item, newQty),
          onRemove: () => onRemoveItem(item.product.id),
        );
      },
    );
  }
}
