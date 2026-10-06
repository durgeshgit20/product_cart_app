import 'dart:async';

import 'package:product_cart_app/features/products/domain/entities/product.dart';
import 'package:product_cart_app/features/products/domain/repositories/i_product_repository.dart';

/// In-memory [IProductRepository]. Call [publish] to push a catalog onto
/// [productStream], as a fetch would.
class FakeProductRepository implements IProductRepository {
  final _controller = StreamController<List<Product>>.broadcast();
  List<Product> _current;

  /// [current] is a catalog already published before anyone listens.
  FakeProductRepository([List<Product> current = const []])
    : _current = List.of(current);

  void publish(List<Product> products) {
    _current = List.of(products);
    _controller.add(_current);
  }

  @override
  Stream<List<Product>> get productStream => _controller.stream;

  @override
  List<Product> get currentProducts => List.unmodifiable(_current);

  @override
  Future<List<Product>> fetchProducts({String? scenario}) async => _current;
}
