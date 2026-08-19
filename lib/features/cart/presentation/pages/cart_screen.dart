import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../widgets/cart_empty_view.dart';
import '../widgets/cart_item_list.dart';
import '../widgets/cart_summary_bottom_sheet.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Shopping Cart'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return CartEmptyView(
              onExplore: () {
                Navigator.pop(context);
              },
            );
          }

          return Column(
            children: [
              Expanded(
                child: CartItemList(
                  items: state.items,
                  onQuantityChanged: (item, newQty) {
                    if (newQty <= 0) {
                      context.read<CartBloc>().add(RemoveFromCartEvent(item.product.id));
                    } else {
                      context.read<CartBloc>().add(UpdateQuantityEvent(
                            productId: item.product.id,
                            newQuantity: newQty,
                          ));
                    }
                  },
                  onRemoveItem: (productId) {
                    context.read<CartBloc>().add(RemoveFromCartEvent(productId));
                  },
                ),
              ),
              CartSummaryBottomSheet(
                subtotal: state.subtotal,
                tax: state.tax,
                grandTotal: state.grandTotal,
                hasOutOfStockItem: state.hasOutOfStockItem,
                onCheckout: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checkout successful!')),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

