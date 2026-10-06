import 'dart:async';

import 'package:product_cart_app/features/products/domain/entities/product.dart';
import 'package:product_cart_app/features/products/domain/repositories/i_product_repository.dart';

/// In-memory [IProductRepository] whose catalog stream the test drives with
/// [publish]. Like the real one, the stream is broadcast with no replay.
class FakeProductRepository implements IProductRepository {
  final _controller = StreamController<List<Product>>.broadcast();
  List<Product> _current = const [];

  /// Whether anything is listening to [productStream].
  bool get hasListener => _controller.hasListener;

  /// Publishes [products] as the latest catalog.
  void publish(List<Product> products) {
    _current = products;
    _controller.add(products);
  }

  @override
  Future<List<Product>> fetchProducts({String? scenario}) async => _current;

  @override
  Stream<List<Product>> get productStream => _controller.stream;

  @override
  List<Product> get currentProducts => _current;
}
