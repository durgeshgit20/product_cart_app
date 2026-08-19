import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductTile({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.deepPurple,
                        ),
                      ),
                      if (product.isOutOfStock)
                        const Chip(
                          label: Text('Out of Stock', style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.redAccent,
                          labelStyle: TextStyle(color: Colors.white),
                          padding: EdgeInsets.zero,
                        )
                      else
                        BlocBuilder<CartBloc, CartState>(
                          builder: (context, cartState) {
                            final cartItem = cartState.items.firstWhere(
                              (item) => item.product.id == product.id,
                              orElse: () => CartItem(
                                product: product,
                                quantity: 0,
                                priceAtAddition: product.price,
                              ),
                            );
                            final quantity = cartItem.quantity;

                            if (quantity > 0) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.deepPurple.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        if (quantity == 1) {
                                          context.read<CartBloc>().add(RemoveFromCartEvent(product.id));
                                        } else {
                                          context.read<CartBloc>().add(UpdateQuantityEvent(
                                                productId: product.id,
                                                newQuantity: quantity - 1,
                                              ));
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(Icons.remove, size: 16, color: Colors.deepPurple),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        '$quantity',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        context.read<CartBloc>().add(UpdateQuantityEvent(
                                              productId: product.id,
                                              newQuantity: quantity + 1,
                                            ));
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(Icons.add, size: 16, color: Colors.deepPurple),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ElevatedButton.icon(
                              key: Key('add_to_cart_${product.id}'),
                              onPressed: onAddToCart,
                              icon: const Icon(Icons.add_shopping_cart, size: 16),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          },
                        ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
