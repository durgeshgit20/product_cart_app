import 'dart:async';
import 'package:injectable/injectable.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../datasources/product_remote_data_source.dart';

@Injectable(as: IProductRepository)
class ProductRepositoryImpl implements IProductRepository {
  final IProductRemoteDataSource remoteDataSource;

  final _productStreamController = StreamController<List<Product>>.broadcast();
  List<Product> _cachedProducts = [];

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<Product>> get productStream => _productStreamController.stream;

  @override
  List<Product> get currentProducts => List.unmodifiable(_cachedProducts);

  @override
  Future<List<Product>> fetchProducts({
    String? scenario,
  }) async {
    try {
      final dtos = await remoteDataSource.getProducts(
        scenario: scenario,
      );
      _cachedProducts = dtos.map((dto) => dto.toEntity()).toList();
      _productStreamController.add(_cachedProducts);
      return _cachedProducts;
    } catch (e) {
      _cachedProducts = [];
      _productStreamController.add(_cachedProducts);
      rethrow;
    }
  }
}
