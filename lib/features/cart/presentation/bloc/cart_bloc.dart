import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/cart_item.dart';
import '../../../products/domain/repositories/i_product_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

@injectable
class CartBloc extends Bloc<CartEvent, CartState> {
  IProductRepository _productRepository;
  StreamSubscription? _productSubscription;

  CartBloc({required IProductRepository productRepository})
      : _productRepository = productRepository,
        super(const CartState()) {
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<SyncCartWithProductsEvent>(_onSyncCartWithProducts);

    _subscribeToRepository();
  }

  void _subscribeToRepository() {
    _productSubscription?.cancel();
    _productSubscription = _productRepository.productStream.listen((products) {
      add(SyncCartWithProductsEvent(products));
    });
  }

  void updateRepository(IProductRepository newRepository) {
    _productRepository = newRepository;
    _subscribeToRepository();
  }

  void _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == event.product.id,
    );

    List<CartItem> updatedItems = List.from(state.items);

    if (existingIndex >= 0) {
      final existingItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
    } else {
      updatedItems.add(CartItem(
        product: event.product,
        quantity: 1,
        priceAtAddition: event.product.price,
      ));
    }

    emit(state.copyWith(items: updatedItems, clearNotification: true));
  }

  void _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) {
    final updatedItems = state.items
        .where((item) => item.product.id != event.productId)
        .toList();
    emit(state.copyWith(items: updatedItems, clearNotification: true));
  }

  void _onUpdateQuantity(UpdateQuantityEvent event, Emitter<CartState> emit) {
    if (event.newQuantity <= 0) {
      add(RemoveFromCartEvent(event.productId));
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.product.id == event.productId) {
        return item.copyWith(quantity: event.newQuantity);
      }
      return item;
    }).toList();

    emit(state.copyWith(items: updatedItems, clearNotification: true));
  }

  void _onSyncCartWithProducts(
    SyncCartWithProductsEvent event,
    Emitter<CartState> emit,
  ) {
    if (state.items.isEmpty) return;

    List<String> priceChangeNotifications = [];

    final updatedItems = state.items.map((cartItem) {
      final matchingProduct = event.updatedProducts.firstWhere(
        (p) => p.id == cartItem.product.id,
        orElse: () => cartItem.product,
      );

      final priceChanged = matchingProduct.price != cartItem.product.price;
      if (priceChanged) {
        priceChangeNotifications.add(
          'Price of ${matchingProduct.name} updated: \$${cartItem.product.price.toStringAsFixed(2)} → \$${matchingProduct.price.toStringAsFixed(2)}',
        );
      }

      return cartItem.copyWith(
        product: matchingProduct,
        hasPriceChanged: priceChanged,
        previousPrice: priceChanged ? cartItem.product.price : cartItem.previousPrice,
      );
    }).toList();

    final notification = priceChangeNotifications.isNotEmpty
        ? priceChangeNotifications.join('\n')
        : null;

    emit(state.copyWith(
      items: updatedItems,
      notificationMessage: notification,
    ));
  }

  @override
  Future<void> close() {
    _productSubscription?.cancel();
    return super.close();
  }
}
