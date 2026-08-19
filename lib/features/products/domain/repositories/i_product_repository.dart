import '../entities/product.dart';

abstract class IProductRepository {
  /// Fetches products from backend
  Future<List<Product>> fetchProducts({
    String? scenario,
  });

  /// Broadcasts stream of real-time updated products
  Stream<List<Product>> get productStream;

  /// Current cached product list
  List<Product> get currentProducts;
}
